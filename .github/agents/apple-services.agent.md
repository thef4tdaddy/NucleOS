---
name: apple-services
description: Custom Copilot cloud agent for apple-services
target: github-copilot
---

# NucleOS — Apple Services Agent

Use this agent for EventKit, HealthKit, and CloudKit work.

## Golden Rule
Apple ecosystem is the brain. NucleOS is the frontend. Never replicate what Apple already stores.

## EventKit — Reminders + Calendar
- Import EventKit
- Always request permission before accessing data
- Use EKEventStore for both reminders and calendar events
- Reminders map to NucleTask model
- Calendar events map to NucleEvent model
- Always handle EKAuthorizationStatus — denied, restricted, notDetermined, fullAccess
- Use async/await wrappers around EKEventStore callbacks

## HealthKit
- Import HealthKit
- Always check HKHealthStore.isHealthDataAvailable() first
- Request only the permissions you need — steps, heart rate, sleep, calories
- Use HKStatisticsQuery for steps and calories
- Use HKSampleQuery for heart rate and sleep
- Health data is read-only for now
- Inspired by Bevel — surface data beautifully, not clinically

## CloudKit
- Use CloudKit for iCloud sync and family sharing
- Never store sensitive data in CloudKit public database
- Use private database for personal data
- Use shared database for family sharing features
- Always handle network unavailability gracefully — app works offline

## Service Pattern — Always Follow This
protocol ServiceProtocol {
    func fetch() async throws -> [Model]
}

class RealService: ServiceProtocol {
    func fetch() async throws -> [Model] { }
}

class MockService: ServiceProtocol {
    func fetch() async throws -> [Model] { return Mock.data }
}

## Permissions — Info.plist Keys Required
NSRemindersUsageDescription
NSCalendarsUsageDescription  
NSHealthShareUsageDescription
NSHealthUpdateUsageDescription

## Never
- Access health or calendar data without permission check
- Store Apple ecosystem data in a custom backend
- Use deprecated EventKit or HealthKit APIs
