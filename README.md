# Expense Splitter App

A comprehensive iOS expense splitting application built with SwiftUI and Core Data, designed to help friends and groups manage shared expenses efficiently.

## Overview

The Expense Splitter app allows users to:
- Create and manage expense groups
- Add friends and invite them to groups
- Track shared expenses with automatic splitting
- Manage user profiles with contact information
- Handle group invitations and friend requests

## Core Data Model

The app uses Core Data for persistent storage with the following entities:

### Person Entity
- **Attributes**: `id` (UUID), `name` (String), `username` (String), `phoneNumber` (String), `email` (String), `isCurrentUser` (Boolean)
- **Relationships**: 
  - `groups` (many-to-many with Group) - Groups the person belongs to
  - `expensesPaid` (one-to-many with Expense) - Expenses paid by this person
  - `receivedInvitations` (one-to-many with GroupInvitation) - Invitations received
  - `sentInvitations` (one-to-many with GroupInvitation) - Invitations sent

### Group Entity
- **Attributes**: `id` (UUID), `name` (String), `created` (Date)
- **Relationships**:
  - `members` (many-to-many with Person) - People in the group
  - `expenses` (one-to-many with Expense) - Expenses in the group
  - `invitations` (one-to-many with GroupInvitation) - Pending invitations

### Expense Entity
- **Attributes**: `id` (UUID), `amount` (Decimal), `description` (String), `date` (Date)
- **Relationships**:
  - `group` (many-to-one with Group) - The group this expense belongs to
  - `payer` (many-to-one with Person) - Who paid the expense
  - `lineItems` (one-to-many with LineItem) - Individual items in the expense

### LineItem Entity
- **Attributes**: `id` (UUID), `description` (String), `amount` (Decimal)
- **Relationships**:
  - `expense` (many-to-one with Expense) - The expense this item belongs to
  - `assignedTo` (many-to-one with Person) - Who this item is assigned to

### GroupInvitation Entity
- **Attributes**: `id` (UUID), `status` (String), `created` (Date)
- **Relationships**:
  - `group` (many-to-one with Group) - The group being invited to
  - `inviter` (many-to-one with Person) - Who sent the invitation
  - `invitee` (many-to-one with Person) - Who received the invitation

## Key Features

### User Management
- **User Registration**: New users create profiles with username, name, phone number, and email
- **Profile Management**: Users can edit their profile information
- **Current User Tracking**: The app automatically tracks the current user across sessions

### Friend System
- **Add Friends**: Search for users by username or phone number
- **Friend Management**: View and manage your friends list
- **Friend Requests**: Send and accept friend requests

### Group Management
- **Create Groups**: Users can create new expense groups
- **Auto-join**: Group creators are automatically added as members
- **Group Invitations**: Invite friends to join groups
- **Member Management**: Add/remove members from groups

### Invitation System
- **Group Invitations**: Send invitations to friends to join groups
- **Invitation Management**: Accept or decline group invitations
- **Status Tracking**: Track invitation status (pending, accepted, declined)

## Views and Components

### Main App Structure
- **Expense_SplitterApp**: Main app entry point with user authentication flow
- **UserRegistrationView**: Initial user setup and profile creation
- **GroupListView**: Main dashboard showing all user's groups

### User Management Views
- **UserProfileEditView**: Edit user profile information
- **FriendsView**: Manage friends and send friend requests
- **GroupInvitationView**: View and respond to group invitations

### Group Management Views
- **GroupDetailView**: Detailed view of a specific group
- **AddGroupSheet**: Modal for creating new groups
- **EditGroupSheet**: Modal for editing group information
- **InviteFriendsToGroupView**: Modal for inviting friends to groups

## Services

### UserService
Central service managing user-related operations:
- User profile management
- Friend management
- Group invitation handling
- User search functionality
- Current user state management

### UserManager (Legacy)
Older user management service (being phased out in favor of UserService):
- Basic user profile operations
- Group membership management

## Data Flow

1. **User Registration**: New users create profiles through `UserRegistrationView`
2. **Friend Management**: Users add friends through `FriendsView`
3. **Group Creation**: Users create groups through `GroupListView`
4. **Invitations**: Group creators invite friends through `GroupDetailView`
5. **Invitation Response**: Friends respond to invitations through `GroupInvitationView`

## Technical Architecture

- **Framework**: SwiftUI for UI, Core Data for persistence
- **Data Management**: `@EnvironmentObject` for service injection
- **State Management**: `@Published` properties for reactive updates
- **Navigation**: `NavigationLink` and sheet presentations
- **Data Persistence**: Core Data with automatic relationship management

## Current Status

The app currently provides a solid foundation for:
- ✅ User profile management
- ✅ Friend system
- ✅ Group creation and management
- ✅ Invitation system
- ✅ Basic expense tracking structure

## Future Enhancements

- Expense splitting calculations
- Receipt scanning and OCR
- Automatic tip and tax splitting
- Payment tracking and settlement
- Push notifications for invitations
- Export functionality for expense reports

## Getting Started

1. Open the project in Xcode
2. Build and run on iOS Simulator or device
3. Create a user profile on first launch
4. Add friends and create groups
5. Start managing shared expenses!

## Dependencies

- iOS 18.4+
- Xcode 16+
- SwiftUI
- Core Data