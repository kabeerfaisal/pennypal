# PennyPal — Site Map and Flowcharts

Complete navigation map of the app, with Mermaid flowcharts for the documentation.

How to use: paste any Mermaid block into [Mermaid Live Editor](https://mermaid.live) to get a diagram, or into GitHub/GitLab, Notion, or VS Code (Markdown Preview Mermaid) and it renders automatically.

---

## 1. Full App Structure

Every screen in the app and where it sits.

```mermaid
flowchart TD
    Splash["Splash Screen<br/>piggy bank logo"] --> Onboarding

    Onboarding["Onboarding<br/>6 slides"] --> AuthGate

    AuthGate{"Signed in?"}
    AuthGate -->|No| Login
    AuthGate -->|Yes| Suspended

    Login["Login Screen"] --> StudentApp
    Register["Register Screen"] --> StudentApp

    Login <-->|Create one| Register
    Login -->|Forgot password| ResetMail["Password reset email<br/>sent, no screen"]

    StudentApp["Student App"]
    AdminApp["Admin Panel"]

    AuthGate -->|Role is Admin| AdminApp
    AuthGate -->|Role is Student| StudentApp
    AuthGate -->|IsSuspended true| Suspended

    Suspended["Suspended Screen<br/>reason + appeal"] --> ContactSupport

    subgraph StudentApp ["Student App — 5 tabs"]
        Dash["Dashboard"]
        Trans["Transactions"]
        Budget["Budget"]
        Savings["Savings"]
        Learn["Learning"]
    end

    subgraph AdminApp ["Admin Panel — 5 tabs"]
        AOver["Overview"]
        AUsers["Users"]
        AAnlyt["Analytics"]
        ALearn["Learn"]
        ASupp["Support"]
    end

    StudentApp --- Profile
    StudentApp --- Notifications
    StudentApp --- AIChat

    Profile["Profile & Settings"]
    Notifications["Notifications"]
    AIChat["AI Advisor Chat"]
    About["About"]
    Privacy["Privacy Policy<br/>9 sections"]
```

---

## 2. First Run Flow

What a brand new user sees, in order.

```mermaid
flowchart TD
    Start([App opened]) --> Splash

    Splash --> Check{"Onboarding<br/>seen before?"}
    Check -->|No| Onb1["Welcome to PennyPal"]
    Onb1 --> Onb2["Log every transaction"]
    Onb2 --> Onb3["Stay inside your limits"]
    Onb3 --> Onb4["Save for real goals"]
    Onb4 --> Onb5["Ask anything, by voice or text"]
    Onb5 --> Onb6["What lives where"]
    Onb6 --> Gate

    Check -->|Yes| Gate["Auth Gate"]

    Gate --> Auth{"Signed in?"}
    Auth -->|No| Login
    Auth -->|Yes| Data

    Login --> Reg{"Has an account?"}
    Reg -->|No| Register
    Reg -->|Yes| Data
    Register --> Data

    Data{"Any data<br/>yet?"}
    Data -->|No, brand new| Tour["Guided Tour<br/>7 steps"]
    Data -->|Yes| Dash
    Tour --> Dash

    Dash([Dashboard])

    style Tour fill:#d4edda,stroke:#28a745
    style Data fill:#fff3cd,stroke:#ffc107
```

**Two separate first-run experiences.** Onboarding explains the app before there is an account. The guided tour explains the screen after there is one, and only on an account with no data, so an existing user is never interrupted on an update.

---

## 3. Student Navigation

The five tabs, plus everything reachable from the top bar.

```mermaid
flowchart TD
    Dash["Dashboard tab"]

    Dash --> T1["Transactions tab"]
    Dash --> T2["Budget tab"]
    Dash --> T3["Savings tab"]
    Dash --> T4["Learning tab"]

    Dash -.->|"View All"| T1
    Dash -.->|"View All"| T3
    Dash -.->|"View All: Transactions"| T1
    Dash -.->|"View All: Savings Goals"| T3

    Dash -->|"Green FAB"| AddTx
    Dash -->|"Robot icon"| AI
    Dash -->|"Bell icon"| Notif
    Dash -->|"Person icon"| Profile

    T1 --> TxDetail["Tap a transaction<br/>edit or delete"]
    T1 -->|"Swipe left"| TxDelete["Delete with confirm"]

    T2 --> SetBudget["Set monthly budget"]
    T2 --> SetCat["Set a category limit"]
    T2 --> Export["Export to file"]

    T3 --> GoalList["Goals list"]
    GoalList -->|"Add Goal"| NewGoal["Amount + target date"]
    GoalList -->|"Add money"| AddMoney
    GoalList --> TapGoal["Goal detail"]
    TapGoal --> Milestone["Milestones<br/>add, rename, tick, delete"]

    T4 --> Article["Article reader"]

    AddTx["Add / Edit Transaction<br/>title, amount, category,<br/>payment mode, receipt"]

    AI["AI Advisor<br/>type or voice"]
    AI -->|"Saved to Firestore"| AIHistory["Chat history"]

    Notif["Notifications<br/>unread count"]
    Notif -->|"Mark all read"| Notif
    Notif -->|"Swipe"| NotifDelete["Delete one"]

    Profile["Profile & Settings"]
    Profile --> EditProfile["Edit name and phone"]
    Profile --> Theme["Light / Dark theme"]
    Profile --> Preferences["Student status, avatar,<br/>alert preference"]
    Profile --> Currency["Currency"]
    Profile --> Logout["Logout"]
    Profile --> SelfDelete["Delete my account<br/>password required"]

    Dash --> Menu["Three dots menu"]
    Menu --> Profile
    Menu --> AI
    Menu --> Feedback["Feedback & Queries"]
    Menu --> Support["Contact Support"]
    Menu --> About["About"]
    About --> Privacy

    style SelfDelete fill:#f8d7da,stroke:#dc3545
    style AddTx fill:#d4edda,stroke:#28a745
    style AI fill:#e2e3ff,stroke:#6610f2
```

---

## 4. The Three Dots Menu

Everything in the top bar overflow, in the order it appears.

```mermaid
flowchart LR
    Menu["Three dots"] --> M1["AI Advisor"]
    Menu --> M2["Profile & Settings"]
    Menu --> M3["Feedback & Queries"]
    Menu --> M4["Contact Support"]
    Menu --> M5["About"]
    Menu --> M6["Logout"]

    M2 --> P1["Edit profile"]
    P1 --> P1a["Light Theme"]
    P1 --> P1b["Dark Theme"]
    P1 --> P1c["Currency"]
    P1 --> P1d["Student preferences"]
    P1 --> P1e["Logout"]
    P1 --> P1f["Delete my account"]

    M5 --> A1["Privacy Policy"]
    A1 --> A1a["What we collect"]
    A1 --> A1b["What we do not collect"]
    A1 --> A1c["Who can see your data"]
    A1 --> A1d["Where your data is stored"]
    A1 --> A1e["The AI advisor"]
    A1 --> A1f["Notifications on your phone"]
    A1 --> A1g["Deleting your account"]
    A1 --> A1h["Your choices"]
    A1 --> A1i["Questions"]

    style P1f fill:#f8d7da,stroke:#dc3545
```

---

## 5. Add Transaction Flow

```mermaid
flowchart TD
    Open["Add Transaction"] --> T1["Title"]
    Open --> T2["Amount"]

    Validate{"Both filled<br/>and amount > 0?"}
    Validate -->|No| Error["Toast: fill title and amount<br/>or enter a valid amount"]
    Error --> Validate

    Validate -->|Yes| Cat["Category chips"]
    Cat --> Mode["Payment mode<br/>for expense"]
    Mode --> Income{"Expense<br/>or income?"}
    Income -->|Income| Mode2["Source field"]
    Income -->|Expense| Receipt

    Receipt["Attach receipt photo<br/>camera or gallery"]
    Receipt --> Compress["Compress and store<br/>as base64 in the document"]
    Mode2 --> Save

    Compress --> Save["Save"]
    Save --> Dash["Back to dashboard"]
    Dash --> Notif2["Local notification<br/>expense added"]

    style Compress fill:#fff3cd,stroke:#ffc107
    style Notif2 fill:#d1ecf1,stroke:#17a2b8
```

**Receipts only attach to an expense.** An income entry has no receipt, so the field is hidden rather than shown and ignored. The photo is compressed so it fits the 1 MiB Firestore document limit, which is what keeps the project on the free plan.

---

## 6. Budget and Warning Logic

```mermaid
flowchart TD
    Open["Budget tab"] --> Set{"Budget<br/>set?"}

    Set -->|No zero| Prompt["No budget set yet<br/>prompt to set one"]
    Set -->|Yes| Show["Ring shows percent used"]

    Show --> Warning{"Usage<br/>threshold"}
    Warning -->|Under 80%| Safe["Green<br/>no warning"]
    Warning -->|80 to 99%| Near["Amber<br/>in-app warning"]
    Warning -->|100% or more| Over["Red<br/>notification sent"]

    Near --> Limit["Phone tray notification"]
    Over --> Limit

    Safe --> CatLimit["Per category limits"]
    Near --> CatLimit
    Over --> CatLimit

    CatLimit --> Export["Export data to a file"]

    style Safe fill:#d4edda,stroke:#28a745
    style Near fill:#fff3cd,stroke:#ffc107
    style Over fill:#f8d7da,stroke:#dc3545
    style Limit fill:#d1ecf1,stroke:#17a2b8
```

**A budget of zero is not shown as zero percent used.** It shows a prompt to set one, because an unconfigured budget and a budget of zero spending mean very different things and look identical otherwise.

---

## 7. Savings Goal and Milestone Flow

```mermaid
flowchart TD
    List["Savings tab"] -->|"Add Goal"| Form["Goal name<br/>target amount<br/>target date"]
    Form --> Save["Save"]
    Save --> Bar["Progress bar fills<br/>against the target"]

    Bar -->|"Add money"| Amount["Enter an amount"]
    Amount --> Update["Progress updates"]
    Update --> Bar

    Bar -->|"Tap goal"| Detail["Goal detail screen"]
    Detail --> Milestone["Milestone list"]
    Milestone --> Add["Add milestone"]
    Milestone --> Rename["Rename, keeps ticked state"]
    Milestone --> Tick["Tick or untick"]
    Milestone --> Delete["Delete one"]
    Milestone --> Clear["Clear all"]

    style Bar fill:#d4edda,stroke:#28a745
```

---

## 8. AI Advisor Flow

```mermaid
flowchart TD
    Open["AI Advisor"] --> Mode

    Mode -->|"Type"| Typed["Text message"]
    Mode -->|"Microphone"| Voice["Speech to text"]
    Voice --> Typed

    Typed --> Prompt["Prompt built from the user's<br/>own transactions and budget"]
    Prompt --> API["Groq API, streamed"]
    API --> Stream["Answer arrives word by word"]
    Stream --> MD["Rendered as markdown<br/>bullets, bold"]
    MD --> Save

    Save["Saved to Firestore<br/>Users/uid/Chats/id/Messages"]
    Save --> History["History reloads next time"]

    MD --> Copy["Long press to copy"]
    MD --> Link["Open a link from an answer"]

    style Stream fill:#e2e3ff,stroke:#6610f2
    style Save fill:#d1ecf1,stroke:#17a2b8
```

**The API key is never in the source.** It is read at runtime from a dart-define, a local `.env`, a bundled asset, or `web/env.js`, in that order. That is what keeps it out of version control while still working with a plain `flutter run`.

---

## 9. Account Deletion Flow

The one action in the app that fully completes.

```mermaid
flowchart TD
    Who["Who can delete<br/>an account?"]

    Who -->|Student, own| Self
    Who -->|Admin, other| No["Not possible in the app"]
    Who -->|Admin, own| SelfGuard["Blocked by the guard"]

    Self["Profile to Delete my account"] --> Dialog["Warning dialog<br/>names every data type"]
    Dialog --> PW["Password required"]
    PW --> Reauth["Re-authenticate<br/>Firebase needs a recent sign-in"]

    Reauth -->|"Wrong password"| Reauth
    Reauth -->|OK| DeleteAuth["Delete the Auth record<br/>EMAIL IS RELEASED HERE"]

    DeleteAuth --> Data["Clear transactions, goals,<br/>profile, notifications, chats, feedback"]
    Data --> Out["Signed out, back to Login"]

    No --> Why["Firebase gives clients no way to<br/>remove somebody else's sign-in.<br/>An admin button would clear the data<br/>but leave the email taken."]

    style Self fill:#d4edda,stroke:#28a745
    style DeleteAuth fill:#d1ecf1,stroke:#17a2b8
    style No fill:#f8d7da,stroke:#dc3545
    style Why fill:#f8d7da,stroke:#dc3545
```

**Why the admin has no delete button.** Firebase deliberately exposes no client API for deleting another user's sign in, otherwise any signed in user could delete any other account. An admin button could only clear Firestore, which would leave the email registered and the student unable to sign up again. A control that half works is worse than none, so the button was removed and self service deletion is the answer.

**Order matters.** The sign in record is deleted first. If the second step fails, the data is still intact rather than orphaned under an account that no longer exists.

---

## 10. Admin Panel Navigation

```mermaid
flowchart TD
    Admin["Admin Panel"] --> AOver
    Admin --> AUsers
    Admin --> AAnlyt
    Admin --> ALearn
    Admin --> ASupp

    AOver["Overview tab"]
    AOver --> Stats["Six stat cards<br/>Total Users, Students, Admins,<br/>Open Queries, Total Feedback, Articles"]
    Stats --> Recent["Recent activity list"]

    AUsers["Users tab"]
    AUsers --> Search["Search by name or email"]
    Search --> UserDetail["Student profile"]
    UserDetail --> Role["Change role<br/>Student or Admin"]
    UserDetail --> Suspend["Suspend or restore"]
    Suspend --> Reason["Reason required, shown to the student"]
    UserDetail --> Self["Own account: actions disabled"]

    AAnlyt["Analytics tab"]
    AAnlyt --> Cat["Spending by category<br/>percentage breakdown"]

    ALearn["Learn tab"]
    ALearn --> Article["Add, edit, reorder articles"]
    Article --> Fallback["If empty, three built-in<br/>lessons are shown"]

    ASupp["Support tab"]
    ASupp --> Inbox["Student queries inbox"]
    Inbox --> Reply["Write a reply"]
    Reply --> Student["Student sees it in<br/>Feedback and Queries"]

    style Stats fill:#d1ecf1,stroke:#17a2b8
    style UserDetail fill:#fff3cd,stroke:#ffc107
    style Self fill:#f8d7da,stroke:#dc3545
```

---

## 11. Suspension Flow

```mermaid
flowchart TD
    Admin["Admin suspends a student<br/>with a reason"] --> Write["IsSuspended true<br/>SuspendedAt, SuspendedReason"]

    Write --> Student["Student signs in"]
    Student --> Order{"Which check<br/>runs first?"}

    Order -->|"Suspension is checked<br/>before the role"| Blocked["Suspended screen"]
    Order -->|"If it were after"| WouldPass["Role would decide instead"]

    Blocked --> Msg["Full screen lock<br/>with the reason shown"]
    Msg --> Appeal["Contact admin button"]
    Appeal --> Inbox["Lands in the admin's<br/>Feedback inbox"]

    Admin --> Restore["Restore access<br/>clears the flag"]

    style Blocked fill:#f8d7da,stroke:#dc3545
    style WouldPass fill:#f8d7da,stroke:#dc3545,stroke-dasharray: 5 5
    style Inbox fill:#d4edda,stroke:#28a745
```

**Suspension is checked before the role.** That ordering means a suspended admin is locked out too, not just a suspended student. The dashed box shows the path that would exist if the order were reversed.

---

## 12. Feedback and Support Flow

Two separate routes into the admin inbox.

```mermaid
flowchart TD
    Student["Student"] --> M1["Three dots menu"]

    M1 --> F1["Feedback and Queries<br/>three types:<br/>Feedback, Query, Bug"]
    M1 --> F2["Contact Support<br/>topic, subject, message"]

    F1 --> Sub["Subject optional<br/>Message required"]
    F2 --> Sub2["Topic, subject, message<br/>described in detail"]

    Sub --> Inbox
    Sub2 --> Inbox

    Inbox["Admin Support tab"] --> Read["Open the item"]
    Read --> Status{"Status"}
    Status -->|Open| Reply["Reply box"]
    Reply --> Sent["Reply sent to student"]
    Sent --> Student

    Student --> Suspended["Suspended screen"] --> Appeal["Contact admin"]
    Appeal --> Inbox

    style Inbox fill:#fff3cd,stroke:#ffc107
    style Reply fill:#d4edda,stroke:#28a745
```

**A suspended student's appeal button routes into this same inbox.** That is deliberate, because a locked out student has no other way to reach an admin.

---

## 13. Notification Flow

```mermaid
flowchart TD
    Event["What happened"] --> Check{"Notification type"}

    Check -->|"Budget or limit<br/>exceeded"| Tray["Goes to the system tray<br/>via flutter_local_notifications"]
    Check -->|"Goal reached"| Tray
    Check -->|"Admin action"| Tray
    Check -->|"Routine expense added"| InApp["Stays inside the app only"]

    Tray --> Channels["Three channels<br/>budget, limits, admin"]
    Channels --> Badge["Phone tray alert<br/>with a badge count"]

    InApp --> Banner["Notice banner in the app"]

    Banner --> History["Written to Firestore<br/>Notifications subcollection"]

    Tray --> History
    History --> Centre["Notifications screen<br/>unread count, mark all read,<br/>swipe to delete"]

    style Tray fill:#d1ecf1,stroke:#17a2b8
    style InApp fill:#e2e3ff,stroke:#6610f2
    style History fill:#d4edda,stroke:#28a745
```

**Routine notifications stay inside the app on purpose.** Only budget, limit, goal, and admin events interrupt on the phone tray. Everything is written to Firestore either way, so the full history is the same.

**No FCM.** Cloud Messaging needs the Blaze plan. Notifications are generated in the app and a real system tray alert is raised locally, so the phone still buzzes without a server.

---

## 14. Data Model

How the Firestore collections are organised.

```mermaid
erDiagram
    Users ||--o{ Transactions : has
    Users ||--o{ SavingGoals : has
    Users ||--o{ Profile : has
    Users ||--o{ Notifications : has
    Users ||--o{ Chats : has
    Chats ||--o{ Messages : contains
    Users ||--o{ Feedbacks : writes

    Users {
        string Name
        string Email
        string Role "Student or Admin"
        bool IsSuspended
        string SuspendedReason
        timestamp SuspendedAt
    }
    Transactions {
        string Title
        number Amount
        string Type "expense or income"
        string Category
        string PaymentMode
        string ReceiptData "base64, optional"
        date Date
    }
    SavingGoals {
        string Title
        number Target
        number Saved
        date TargetDate
    }
    Notifications {
        string Title
        string Body
        string Level
        bool Read
        timestamp Time
    }
    Feedbacks {
        string UserId
        string Type "Feedback, Query or Bug"
        string Subject
        string Message
        string Status "Open or Answered"
        string AdminReply
    }
```

`Chats` is two levels deep, `Users/uid/Chats/chatId/Messages/messageId`, which is how the AI history is kept per user.

---

## 15. Role Based Access

What each role can reach.

```mermaid
flowchart LR
    Auth["Auth Gate"] --> Role{"Role"}

    Role -->|Student| S1["5 tabs"]
    Role -->|Admin| A1["5 admin tabs"]
    Role -->|Suspended| X1["Nothing, blocked screen"]

    S1 --> S2["Dashboard, Transactions,<br/>Budget, Savings, Learning"]
    S2 --> S3["AI advisor, notifications,<br/>profile, feedback, support"]
    S3 --> S4["Delete own account"]

    A1 --> A2["Overview, Users,<br/>Analytics, Learn, Support"]
    A2 --> A3["Change roles, suspend<br/>and restore accounts"]
    A3 --> A4["Publish lessons,<br/>reply to queries"]
    A4 --> A5["Cannot delete an account,<br/>cannot target own account"]

    X1 --> X2["Reason shown, appeal button<br/>to the admin inbox"]

    style X1 fill:#f8d7da,stroke:#dc3545
    style A5 fill:#fff3cd,stroke:#ffc107
    style S4 fill:#d4edda,stroke:#28a745
```

---

## 16. Onboarding and Tour Content

The actual copy, in order.

```mermaid
flowchart LR
    subgraph Onb ["Onboarding — before sign up"]
        O1["1. Welcome to PennyPal"]
        O2["2. Log every transaction"]
        O3["3. Stay inside your limits"]
        O4["4. Save for real goals"]
        O5["5. Ask anything, by voice or text"]
        O6["6. What lives where"]
        O1 --> O2 --> O3 --> O4 --> O5 --> O6
    end

    subgraph Tour ["Guided tour — after sign up, once"]
        T1["1. Your screen at a glance"]
        T2["2. Ask the AI anything"]
        T3["3. Balance, spent and income"]
        T4["4. Your monthly budget"]
        T5["5. Recent activity"]
        T6["6. Add a transaction"]
        T7["7. Everything lives down here"]
        T1 --> T2 --> T3 --> T4 --> T5 --> T6 --> T7
    end
```

Both are stored in a preference rather than derived from the account, so a student who skips is never shown it again and an existing user is never interrupted on an update. Only one tour can ever be on screen, even if the dashboard builds more than once.

---

## 17. Navigation Structure Reference

A plain list, for writing documentation that does not need a diagram.

### Student tabs
| Tab | Screen | Key actions |
|---|---|---|
| Dashboard | Home | View All buttons, Add Transaction FAB, AI link, bell, profile |
| Transactions | Full list | Search, filters, date range, swipe delete, tap to edit |
| Budget | Limits | Set monthly budget, per category limits, export |
| Savings | Goals | Add goal, add money, milestones |
| Learning | Lessons | Read articles |

### Top bar
| Element | Goes to |
|---|---|
| Piggy bank logo | Wordmark, no action |
| Bell icon | Notifications screen |
| Person icon | Profile and Settings |
| Three dots | AI Advisor, Profile, Feedback, Contact Support, About, Logout |

### Profile section
| Item | What it does |
|---|---|
| Edit profile | Name and phone |
| Student preferences | Status, avatar, alert preference |
| Currency | Display currency |
| Light Theme | Switches to the white theme |
| Dark Theme | True black, the default look |
| Logout | Signs out and returns to Login |
| Delete my account | Password required, removes everything including the sign in |

### Admin tabs
| Tab | Screen | Key actions |
|---|---|---|
| Overview | 6 stat cards | Recent activity |
| Users | Search and list | Change role, suspend, restore |
| Analytics | Category breakdown | Percentage of spending |
| Learn | Article list | Add, edit, reorder, delete |
| Support | Query inbox | Reply to students |

### Privacy policy sections
1. What we collect
2. What we do not collect
3. Who can see your data
4. Where your data is stored
5. The AI advisor
6. Notifications on your phone
7. Deleting your account
8. Your choices
9. Questions

---

## 18. Screen Count

Roughly how the screens add up, useful for a documentation summary.

| Area | Screens |
|---|---|
| Entry | Splash, Onboarding, Auth Gate, Login, Register, Suspended |
| Student tabs | Dashboard, Transactions, Budget, Savings, Learning |
| Detail screens | Add Transaction, Goal detail, Article reader, Receipt viewer |
| Tools | AI Advisor, Notifications |
| Settings | Profile, About, Privacy Policy, Feedback, Contact Support |
| Admin | Admin shell, Overview, Users, User detail, Analytics, Learn, Support |

**Total: 24 screens**

---

## Rendering Notes

| Mermaid | Notes |
|---|---|
| `<br/>` inside a node label | Renders as a line break. Do not use `\n` |
| `subgraph` | Used above to group the student and admin tabs |
| `stroke-dasharray: 5 5` | Used for the counterfactual path in diagram 11 |
| `style` lines | Colour only, for readability in print |
| If a diagram fails | Paste it into mermaid.live to see the exact error |

**Exporting as an image.** Open the diagram at [mermaid.live](https://mermaid.live), then use the Actions menu to download an SVG or PNG. SVG stays sharp at any size, which is what you want for a document that may be printed.
