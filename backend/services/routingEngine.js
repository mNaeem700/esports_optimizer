/**
 * Relay routing engine.
 *
 * NOTE ON HONESTY: A real neural-network relay selector needs months of
 * real historical latency data per relay/region/ISP/time-of-day to train
 * on. We don't have that data, so shipping a fake "trained model" would
 * just be theater. Instead this is a transparent, tunable weighted-scoring
 * heuristic that uses the same input features a model would use
 * (measured latency, jitter, packet loss, current load, geo-distance).
 *
 * This is a legitimate, production-usable approach on day one, and it's
 * a drop-in interface: once you have real usage data, swap
 * `scoreRelay()` for a call to a trained model (e.g. an ONNX/TF.js model)
 * without changing any calling code.
 */

function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

/**
 * Lower score = better relay.
 * Weighs: measured latency, jitter, packet loss, current load %, distance.
 */
function scoreRelay(userLoc, relay, measuredLatencyMs) {
  const distanceKm = haversineKm(userLoc.lat, userLoc.lon, relay.latitude, relay.longitude);
  const loadPct = relay.capacity > 0 ? relay.current_load / relay.capacity : 1;

  const latencyScore = measuredLatencyMs ?? distanceKm / 100; // fallback estimate ~100km/ms
  const loadPenalty = loadPct * 40; // heavily loaded relays get penalized
  const distancePenalty = distanceKm / 200;
  const healthPenalty = relay.health_status === 'healthy' ? 0 : relay.health_status === 'degraded' ? 50 : 10000;

  return latencyScore + loadPenalty + distancePenalty + healthPenalty;
}

/**
 * @param {Object} userLoc { lat, lon }
 * @param {Array} relays list of relay server rows from DB
 * @param {Object} measuredLatencies map of relay_id -> measured ms (optional, from client pings)
 */
function selectBestRelay(userLoc, relays, measuredLatencies = {}) {
  if (!relays || relays.length === 0) return null;

  const scored = relays
    .filter((r) => r.health_status !== 'down')
    .map((r) => ({
      relay: r,
      score: scoreRelay(userLoc, r, measuredLatencies[r.id]),
    }))
    .sort((a, b) => a.score - b.score);

  if (scored.length === 0) return null;

  const best = scored[0];
  return {
    relay: best.relay,
    predictedLatencyMs: Math.round(best.score),
    alternatives: scored.slice(1, 4).map((s) => ({ id: s.relay.id, name: s.relay.server_name, score: Math.round(s.score) })),
  };
}

module.exports = { selectBestRelay, scoreRelay, haversineKm };
