// src/services/notifications.ts
// Notification service for Story Requests (Twilio + Push)

// ============================================================================
// TWILIO CLIENT FOR ELDERS (Phone AI + SMS)
// ============================================================================

export interface TwilioConfig {
  accountSid: string
  authToken: string
  fromNumber: string
}

export interface TwilioClient {
  sendSMS(to: string, body: string): Promise<boolean>
  makeCall(to: string, twiml: string): Promise<boolean>
}

export function createTwilioClient(config: TwilioConfig): TwilioClient {
  return {
    async sendSMS(to: string, body: string): Promise<boolean> {
      // Check if Twilio is configured
      if (!config.accountSid || config.accountSid.includes('placeholder')) {
        console.log(`[Twilio SMS] Would send to ${to}: ${body}`)
        return true
      }

      try {
        const response = await fetch(
          `https://api.twilio.com/2010-04-01/Accounts/${config.accountSid}/Messages.json`,
          {
            method: 'POST',
            headers: {
              Authorization: `Basic ${btoa(`${config.accountSid}:${config.authToken}`)}`,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
              To: to,
              From: config.fromNumber,
              Body: body,
            }),
          }
        )

        if (!response.ok) {
          const error = await response.text()
          console.error('Twilio SMS failed:', error)
          return false
        }

        return true
      } catch (error) {
        console.error('Twilio SMS error:', error)
        return false
      }
    },

    async makeCall(to: string, twiml: string): Promise<boolean> {
      // Check if Twilio is configured
      if (!config.accountSid || config.accountSid.includes('placeholder')) {
        console.log(`[Twilio Call] Would call ${to}`)
        return true
      }

      try {
        const response = await fetch(
          `https://api.twilio.com/2010-04-01/Accounts/${config.accountSid}/Calls.json`,
          {
            method: 'POST',
            headers: {
              Authorization: `Basic ${btoa(`${config.accountSid}:${config.authToken}`)}`,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
              To: to,
              From: config.fromNumber,
              Twiml: twiml,
            }),
          }
        )

        if (!response.ok) {
          const error = await response.text()
          console.error('Twilio Call failed:', error)
          return false
        }

        return true
      } catch (error) {
        console.error('Twilio Call error:', error)
        return false
      }
    },
  }
}

// ============================================================================
// PUSH NOTIFICATIONS FOR APP USERS
// ============================================================================

export interface PushNotificationConfig {
  vapidPublicKey: string
  vapidPrivateKey: string
  subject: string
}

export interface PushSubscription {
  endpoint: string
  keys: {
    p256dh: string
    auth: string
  }
}

export interface PushNotificationPayload {
  title: string
  body: string
  icon?: string
  badge?: string
  tag?: string
  data?: Record<string, string>
  actions?: Array<{
    action: string
    title: string
    icon?: string
  }>
}

export function createPushNotificationService(config: PushNotificationConfig) {
  async function sendPushNotification(
    subscription: PushSubscription,
    payload: PushNotificationPayload
  ): Promise<boolean> {
    // Check if push is configured
    if (!config.vapidPublicKey || config.vapidPublicKey.includes('placeholder')) {
      console.log(`[Push] Would send to ${subscription.endpoint}: ${payload.title}`)
      return true
    }

    try {
      // Encode payload
      const body = JSON.stringify({
        webpush: {
          notification: {
            title: payload.title,
            body: payload.body,
            icon: payload.icon,
            badge: payload.badge,
            tag: payload.tag,
            data: payload.data,
            actions: payload.actions,
          },
          fcmOptions: {
            link: payload.data?.link,
          },
        },
      })

      // Send to push service (simplified - in production use web-push library)
      const response = await fetch(subscription.endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          TTL: '86400',
        },
        body,
      })

      if (!response.ok && response.status !== 410) {
        console.error('Push notification failed:', await response.text())
        return false
      }

      return true
    } catch (error) {
      console.error('Push notification error:', error)
      return false
    }
  }

  async function broadcastToSubscriptions(
    subscriptions: PushSubscription[],
    payload: PushNotificationPayload
  ): Promise<{ sent: number; failed: number }> {
    let sent = 0
    let failed = 0

    await Promise.all(
      subscriptions.map(async (subscription) => {
        const success = await sendPushNotification(subscription, payload)
        if (success) {
          sent++
        } else {
          failed++
        }
      })
    )

    return { sent, failed }
  }

  return {
    sendPushNotification,
    broadcastToSubscriptions,
  }
}

// ============================================================================
// WISDOM REQUEST NOTIFICATION SERVICE
// ============================================================================

export interface WisdomRequestNotification {
  requestId: string
  question: string
  requesterName: string
  targetProfileIds: string[]
}

export interface FamilyMember {
  id: string
  fullName: string | null
  phoneNumber: string | null
  role: string
  pushSubscriptions?: PushSubscription[]
}

export function createWisdomNotificationService(
  twilioClient: TwilioClient,
  pushService: ReturnType<typeof createPushNotificationService>
) {
  async function notifyFamilyMembers(
    request: WisdomRequestNotification,
    familyMembers: FamilyMember[]
  ): Promise<{ appUsersNotified: number; eldersNotified: number }> {
    let appUsersNotified = 0
    let eldersNotified = 0

    const message = createRequestMessage(request)

    for (const member of familyMembers) {
      // Skip the requester (don't notify yourself)
      if (request.targetProfileIds.includes(member.id)) {
        continue
      }

      if (member.role === 'elder' && member.phoneNumber) {
        // Send SMS to elders
        const success = await twilioClient.sendSMS(member.phoneNumber, message)
        if (success) {
          eldersNotified++
        }
      } else if (member.pushSubscriptions && member.pushSubscriptions.length > 0) {
        // Send push notifications to app users
        const payload: PushNotificationPayload = {
          title: 'Family Wisdom Request',
          body: `${requesterName} wants to hear about: "${truncateQuestion(request.question)}"`,
          icon: '/icons/wisdom.png',
          badge: '/icons/badge.png',
          tag: `wisdom-request-${request.requestId}`,
          data: {
            type: 'wisdom_request',
            requestId: request.requestId,
            link: '/wisdom/requests',
          },
          actions: [
            { action: 'accept', title: 'Record Story' },
            { action: 'decline', title: 'Decline' },
          ],
        }

        const result = await pushService.broadcastToSubscriptions(
          member.pushSubscriptions,
          payload
        )
        appUsersNotified += result.sent
      }
    }

    return { appUsersNotified, eldersNotified }
  }

  return {
    notifyFamilyMembers,
  }
}

// ============================================================================
// HELPERS
// ============================================================================

function createRequestMessage(request: WisdomRequestNotification): string {
  return `Family Story Request from ${request.requesterName}:\n\n"${truncateQuestion(request.question)}"\n\nShare your story to help the family! Reply or call to record.`
}

function truncateQuestion(question: string, maxLength: number = 100): string {
  if (question.length <= maxLength) return question
  return question.substring(0, maxLength - 3) + '...'
}

// ============================================================================
// DEFAULT EXPORTS
// ============================================================================

export function createNotificationServices(env: {
  TWILIO_ACCOUNT_SID?: string
  TWILIO_AUTH_TOKEN?: string
  TWILIO_PHONE_NUMBER?: string
  VAPID_PUBLIC_KEY?: string
  VAPID_PRIVATE_KEY?: string
  VAPID_SUBJECT?: string
}) {
  const twilioClient = createTwilioClient({
    accountSid: env.TWILIO_ACCOUNT_SID || '',
    authToken: env.TWILIO_AUTH_TOKEN || '',
    fromNumber: env.TWILIO_PHONE_NUMBER || '',
  })

  const pushService = createPushNotificationService({
    vapidPublicKey: env.VAPID_PUBLIC_KEY || '',
    vapidPrivateKey: env.VAPID_PRIVATE_KEY || '',
    subject: env.VAPID_SUBJECT || 'mailto:family@storyrd.app',
  })

  return {
    twilioClient,
    pushService,
  }
}
