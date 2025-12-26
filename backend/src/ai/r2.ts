// src/utils/r2.ts

export interface R2UploadResult {
    key: string;
    url: string;
  }

  export interface R2UploadOptions {
    contentType: string;
    cacheControl?: string;
  }

  export async function uploadToR2(
    bucket: R2Bucket,
    key: string,
    buffer: Buffer,
    options: R2UploadOptions
  ): Promise<R2UploadResult> {
    await bucket.put(key, buffer, {
      httpMetadata: {
        contentType: options.contentType,
      },
    });

    const url = `https://your-r2-domain.com/${key}`;

    return { key, url };
  }

  export async function downloadFromR2(
    bucket: R2Bucket,
    key: string
  ): Promise<Buffer> {
    const object = await bucket.get(key);

    if (!object) {
      throw new Error(`File not found: ${key}`);
    }

    return Buffer.from(await object.arrayBuffer());
  }

  export function generateStorageKey(
    type: 'audio' | 'image' | 'temp',
    userId: string,
    filename: string
  ): string {
    const timestamp = Date.now();
    const randomId = Math.random().toString(36).substring(2, 9);
    return `${type}/${userId}/${timestamp}_${randomId}_${filename}`;
  }