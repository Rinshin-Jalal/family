export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxAttempts: number = 3
): Promise<T> {
  let lastError: Error;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      if (!isRetryableError(error) || attempt === maxAttempts) {
        throw lastError;
      }

      const waitTime = Math.pow(2, attempt - 1) * 1000;
      await sleep(waitTime);
    }
  }

  throw lastError!;
}

export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export function isRetryableError(error: unknown): boolean {
  if (!(error instanceof Error)) {
    return false;
  }

  const errorMessage = error.message.toLowerCase();

  // Retryable errors
  const retryablePatterns = [
    'rate limit',
    'too many requests',
    'timeout',
    'econnreset',
    'etimedout',
    'enotfound',
    'fetch failed',
    'network error',
    '529',
    '503',
    '502',
  ];

  // Don't retry - permanent errors
  const nonRetryablePatterns = [
    'unauthorized',
    'authentication',
    '404',
    'not found',
    'invalid',
    'bad request',
    '400',
    '401',
    '403',
  ];

  // Check non-retryable first (block these)
  if (nonRetryablePatterns.some(pattern => errorMessage.includes(pattern))) {
    return false;
  }

  // Check retryable patterns
  return retryablePatterns.some(pattern => errorMessage.includes(pattern));
}

