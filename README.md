# Expense Splitter App

A comprehensive iOS expense splitting application built with SwiftUI, Firebase, and Core Data, designed to help friends and groups manage shared expenses efficiently.

## Overview

The Expense Splitter app allows users to:
- Create and manage expense groups
- Add friends and invite them to groups
- Track shared expenses with automatic splitting
- Manage user profiles with contact information
- Handle group invitations and friend requests

## Data Architecture

The app uses a hybrid approach with Firebase for real-time features and Core Data for local persistence:

### Firebase Integration
- **Authentication**: User sign-up, sign-in, and session management
- **Real-time Database**: User profiles, friend requests, and groups
- **Cloud Storage**: Centralized data accessible across devices

### Core Data Model (Legacy)

The app maintains Core Data for backward compatibility and local features:

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

### Authentication & User Management
- **Firebase Authentication**: Secure user sign-up and sign-in with email/password
- **Username Login**: Login with either email or username
- **Profile Management**: Users can edit their profile information
- **Password Requirements**: Minimum 8 characters for security

### Friend System (Firebase)
- **Add Friends**: Search for users by username with real-time results
- **Friend Requests**: Send and accept friend requests with real-time updates
- **Friends List**: View and manage your friends list with search functionality
- **Real-time Updates**: Friend requests and status changes sync instantly

### Group Management (Firebase)
- **Create Groups**: Users can create new expense groups stored in Firebase
- **Group Display**: View all groups with creator information
- **Group Deletion**: Group creators can delete their groups
- **Real-time Sync**: Group changes sync across all devices

### Legacy Features (Core Data)
- **Local Data**: Maintains backward compatibility with existing data
- **Offline Support**: Core Data provides offline functionality

## Views and Components

### Main App Structure
- **Expense_SplitterApp**: Main app entry point with Firebase initialization
- **FirebaseAuthView**: Login/signup interface with Firebase authentication
- **GroupListView**: Main dashboard showing all user's groups (Firebase)

### Firebase Views
- **FirebaseFriendsView**: Search and add friends using Firebase
- **FirebaseFriendsListView**: Display current user's friends list
- **FirebaseFriendRequestsView**: Manage incoming friend requests
- **FirebaseGroupDetailView**: Display Firebase group details

### Legacy Views (Core Data)
- **UserRegistrationView**: Initial user setup and profile creation
- **UserProfileEditView**: Edit user profile information (hybrid Firebase/Core Data)
- **FriendsView**: Legacy friend management
- **GroupDetailView**: Detailed view of a specific group
- **GroupInvitationView**: View and respond to group invitations

## Services

### FirebaseService
Primary service for Firebase operations:
- **Authentication**: User sign-up, sign-in, sign-out
- **User Management**: Profile creation and updates
- **Friend System**: Friend requests, acceptance, and management
- **Group Management**: Create, delete, and manage groups
- **Real-time Updates**: Live data synchronization across devices

### UserService (Legacy)
Core Data service for local operations:
- User profile management (fallback)
- Local data persistence
- Backward compatibility

## Data Flow

### Firebase Flow (Primary)
1. **Authentication**: Users sign up/sign in through `FirebaseAuthView`
2. **Friend Management**: Users add friends through `FirebaseFriendsView`
3. **Group Creation**: Users create groups through `GroupListView` (Firebase)
4. **Real-time Updates**: All changes sync instantly across devices

### Legacy Flow (Core Data)
1. **User Registration**: New users create profiles through `UserRegistrationView`
2. **Local Management**: Friends and groups managed locally
3. **Offline Support**: Works without internet connection

## Technical Architecture

- **Framework**: SwiftUI for UI, Firebase for cloud services, Core Data for local persistence
- **Authentication**: Firebase Auth with email/password and username support
- **Database**: Firestore for real-time cloud data, Core Data for local storage
- **Data Management**: `@EnvironmentObject` for service injection
- **State Management**: `@Published` properties for reactive updates
- **Real-time Updates**: Firestore listeners for live data synchronization
- **Navigation**: `NavigationLink` and sheet presentations

## Current Status

The app currently provides a solid foundation for:
- ✅ **Firebase Authentication**: Secure user sign-up and sign-in
- ✅ **User Profile Management**: Create and edit user profiles
- ✅ **Friend System**: Search, add, and manage friends with real-time updates
- ✅ **Group Creation**: Create and delete groups with Firebase storage
- ✅ **Real-time Data Sync**: All changes sync instantly across devices
- ✅ **Hybrid Architecture**: Firebase for new features, Core Data for legacy support

## TODO - Next Steps

### High Priority
1. **Group Member Management**: 
   - Add ability to invite friends to groups
   - Implement group member addition/removal
   - Create group invitation system
   - Allow users to join/leave groups

2. **Group Detail Enhancement**:
   - Expand `FirebaseGroupDetailView` with full functionality
   - Add member list display
   - Implement group settings and management

3. **Expense Management**:
   - Create expense tracking system for groups
   - Implement expense splitting calculations
   - Add expense history and reporting

### Medium Priority
4. **Receipt Processing**:
   - Integrate image recognition for receipt scanning
   - Implement OCR for automatic expense extraction
   - Add manual expense item assignment

5. **Advanced Features**:
   - Automatic tip and tax splitting
   - Payment tracking and settlement
   - Push notifications for invitations
   - Export functionality for expense reports

### Low Priority
6. **UI/UX Improvements**:
   - Enhanced visual design
   - Better error handling and user feedback
   - Accessibility improvements
   - Performance optimizations

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
- Firebase SDK (Auth, Firestore)
- Core Data (legacy support)