# Firestore-only purchase workflow

The Flutter app creates purchase orders and performs state transitions directly through Cloud Firestore. Price validation, allowed fields, ownership, and order states are enforced by `firestore.rules`. There is no Cloud Functions source or deployment target; the active purchase flow does not require the Blaze plan.

## Production setup

1. Back up Firestore. Run the existing contact migration in dry-run mode, review its output, and apply it only if legacy project documents still contain developer phone numbers:

   ```powershell
   npm --prefix functions run migrate:project-contacts
   npm --prefix functions run migrate:project-contacts -- --apply
   ```

2. Deploy only the Firestore configuration:

   ```powershell
   firebase deploy --only firestore:rules,firestore:indexes
   ```

3. Assign the `superAdmin` custom claim from a trusted machine using the existing Admin SDK script and verified account UID:

   ```powershell
   npm --prefix functions run set-super-admin -- <AUTH_UID>
   ```

   The account must match `superAdminEmail` in `config/purchase-settings.json` and have a verified email. The user must sign in again after the claim is applied. These operator scripts use Firebase Admin credentials but do not deploy Cloud Functions.

## Purchase states

- `pending_payment`: created by the buyer; amount must equal the approved project's stored price.
- `pending_admin_review`: buyer reports that the transfer notice was sent; this does not confirm payment.
- `approved` or `rejected`: only a user with the trusted `superAdmin` claim can transition the order. Rejection requires a reason. Approval copies the developer phone from `projectPrivateContacts` into that buyer's order.

The application cannot read WhatsApp messages or attached images. The administrator must inspect the notice and confirm receipt of the Sham Cash transfer manually before approving. The `functions` folder contains only trusted operator utilities and Firestore rule tests; it does not contain deployable Cloud Functions.