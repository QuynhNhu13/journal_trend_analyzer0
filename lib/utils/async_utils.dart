/// Awaits [future], returning [fallback] if it fails.
///
/// Lets an AUXILIARY (enrichment) request degrade gracefully instead of
/// erroring the whole screen. A screen often fans out several parallel requests
/// with `Future.wait`; there, a hiccup in ONE secondary call rejects the whole
/// batch and flips a working page into the error state — which traps the UI
/// (and the E2E auto-retry) in an endless error → retry loop.
///
/// Pattern: await the PRIMARY request directly (it may throw ⇒ real error
/// state), and wrap each secondary request with [orFallback] so it degrades to
/// a safe default instead of taking the page down with it.
Future<T> orFallback<T>(Future<T> future, T fallback) async {
  try {
    return await future;
  } catch (_) {
    return fallback;
  }
}
