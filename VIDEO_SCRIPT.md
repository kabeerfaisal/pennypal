# PennyPal — App Video Script

A point-to-point shooting script. Every scene has three parts: **what to do** (the action), **what to say** (dialogue or voiceover), and **what should be visible on screen** (the thing to draw the eye to).

Format: `[SCENE n]` → `ACTION:` → `SAY:` → `SHOW:`

Target length: 4 to 6 minutes. 18 scenes total.

---

## Before You Record

| Item | Detail |
|---|---|
| Device | A real Android phone, 6 inch screen or larger |
| Theme | Set **Dark Theme**. It is true black, and it looks better on camera than the white one |
| Font size | Leave at default. Do not enlarge it, small text is hard to read in a video |
| Data | Create the test student with a few transactions already in the app. A blank app looks unfinished |
| Budget | Set one number, for example 5000, otherwise the dashboard ring has nothing to show |
| Notifications | Trigger one so the bell shows an unread dot |
| Recording | Screen record on, internal audio **off**, because the voiceover is added afterwards |
| Privacy | Do not use a real name in notifications. Use "Test Student" |

> The single biggest mistake is recording with an empty app. A reviewer needs to see data within the first five seconds.

---

## [SCENE 1] — Splash and Onboarding (0:00–0:20)

**ACTION:** Open the app. Onboarding appears, six slides. Swipe through them.

**SAY (voiceover):**
> "This is PennyPal, a budgeting app built for students. First there is a short six screen tour, and then you create your account."

**SHOW:**
- The **piggy bank logo** on the splash screen
- Slide 1: "Welcome to PennyPal"
- Slide 2: "Log every transaction" with the receipt mention
- Slide 3: "Stay inside your limits"
- Slide 4: "Save for real goals"
- Slide 5: "Ask anything, by voice or text", the AI slide
- Slide 6: "What lives where", which explains the layout

**NOTE:** Pause briefly on slides 5 and 6. They show that both the AI and the layout were explained up front, so a new user never has to hunt for anything.

---

## [SCENE 2] — Sign Up (0:20–0:50)

**ACTION:** Tap "Get started". The sign up form appears. Fill it in:
- Name: `Ali Raza`
- Email: `ali@test.com`
- Password
- Confirm password
- Phone number

**SAY (voiceover):**
> "Registration is straightforward. Name, email, password, and phone. The number field shows a live counter, seven to fifteen digits, no more and no less."

**SHOW:**
- The **green tick** under the phone field once it is valid
- The counter updating as you type, for example 7/15 moving to 12/15
- The **Privacy Policy** link on the sign up screen, zoom in on it

**ACTION (optional, 5 seconds):** Open the Privacy Policy, then go back.

**SAY (voiceover):**
> "The privacy policy is readable before you even sign up. It is on the sign in screen as well. It is required, not optional."

**IMPORTANT:** After registration the guided tour will **not** appear, because the account already has data in it. Scenes 1 and 3 already cover that.

---

## [SCENE 3] — Guided Tour (0:50–1:10)

> **Record this scene only with an account that has no transactions in it.** Create a fresh test account for it. The tour only shows on a new account.

**ACTION:** After signing in, the dashboard appears with the tour overlay, starting at "1 of 7".

**SAY (voiceover):**
> "After signing in, a short tour highlights things on screen one at a time. The top bar, the AI link, the stat cards, the budget, the transactions, the add button, and the bottom navigation. It shows once and never again."

**SHOW:** Move through three or four steps rather than skipping. This is a point to point feature that most other apps in this category do not have.

**NOTE:** This scene is optional. If you are short on time, the onboarding from Scene 1 makes the same point. What you must not do is say "a tour appears" and then never show it.

---

## [SCENE 4] — Dashboard and the View All buttons (1:10–1:35)

**ACTION:** Open a new account with no data. The dashboard appears.

**SAY (voiceover):**
> "This is the dashboard. At the top are three numbers, your transactions, your savings goals, and how much you have spent this month. Below that are your savings goals and your recent transactions."

**SHOW:**
- The **"View All"** buttons on Savings Goals and Recent Transactions, in the corner. **Tap them** and they should switch tabs
- The green **"Add Transaction"** button

**IMPORTANT:** The View All buttons do work. They were dead at one point and we fixed them. Showing them is worth it, because it tells a reviewer that the buttons are not just decoration.

**ACTION:** Tap Add Transaction once, then go back.

---

## [SCENE 5] — Add a Transaction and Attach a Receipt (1:35–2:10)

**ACTION:** Tap the green button. Fill in the form:
- Title: `Groceries`
- Amount: `1250`
- Category: choose **Food**
- Payment mode
- **Attach a receipt**, take a photo with the camera

**SAY (voiceover):**
> "Adding a transaction takes about two seconds. Title, amount, category, payment mode. And if you keep a receipt, you can attach a photo of it, stored inside the same document."

**SHOW:**
- The **category chips**, tap one to highlight it
- The **receipt thumbnail** after it is attached
- Tap Save

**NOTE (2 seconds, important):** There is a one second pause while the receipt attaches, because the image is being compressed. That is normal. Do not let it read as a bug in the video.

**SAY (voiceover):**
> "Cloud Storage requires the Blaze plan, which is paid, so we compress the receipt and store it as base64 inside the same document. It stays under the one megabyte limit, and that is enough for a single receipt."

---

## [SCENE 6] — Notifications (2:10–2:25)

**ACTION:** Tap the **bell icon** in the top bar.

**SAY (voiceover):**
> "Whenever you cross a budget or come close to a limit, the app shows a notification inside the app and also on your phone's notification tray. The full history is here, with an unread count."

**SHOW:**
- The notification list
- The **unread dot or count** on the bell
- The **mark all read** button
- **Swipe** one notification away to delete it

**NOTE:** This is not FCM, which needs the Blaze plan. We built an in-app notification and use `flutter_local_notifications` for a real system tray alert. Say this out loud in the voiceover, because it is a genuine technical difference.

---

## [SCENE 7] — Transactions: Search, Filter, Delete (2:25–2:50)

**ACTION:** Tap **Transactions** in the bottom navigation.

**SAY (voiceover):**
> "The full list is here. Search by title or category, filter to expenses or income only, and pick a date range."

**ACTION:**
- Type `Gro` in the search box
- Tap the **All / Expense / Income** filter chips
- Open the date range dropdown
- Show the results bar with a **count and a total**

**SHOW:** A results bar reading something like "3 transactions · Rs 1,450"

**ACTION:** **Swipe left** on a transaction to delete it, then confirm if a confirmation appears.

**SAY (voiceover):**
> "If an entry was wrong, swipe left and delete it. Tap any transaction to edit it."

---

## [SCENE 8] — Budget and the Warning (2:50–3:15)

**ACTION:** Tap **Budget** in the bottom navigation.

**SAY (voiceover):**
> "The budget is set here. A total monthly limit, and a separate limit for each category. As soon as you cross eighty percent, the app warns you, and when you cross the limit itself a notification arrives."

**ACTION:**
- Tap **"Set monthly budget"**, enter 5000, save
- Set a **category limit**, for example 2000 for Food
- Show the progress ring moving

**SHOW:**
- The three numbers: **Total Limit, Spent, Remaining**
- The progress bar moving from green towards yellow or red
- The category breakdown

**IMPORTANT:** If the budget is zero the app shows a "No budget set yet" prompt instead of a ring reading zero percent. That is the correct behaviour. Make sure the budget is set in the video, otherwise this part of the screen looks empty.

---

## [SCENE 9] — Savings Goals and Milestones (3:15–3:45)

**ACTION:** Tap **Savings** in the bottom navigation.

**SAY (voiceover):**
> "Savings goals. A laptop, a trip, an emergency fund, whatever it is. Set an amount and a target date, and whenever you add money the progress bar fills up."

**ACTION:**
- Tap **"Add Goal"**: `Laptop`, 80000, a target date, save
- Tap **"Add money"** on the goal and enter 15000
- Show the progress bar filling
- Tap the goal to open the **detail screen**
- Tap **"Add milestone"**, type `First 20000 saved`, tick it
- Show **rename** and **delete** on a milestone

**SHOW:**
- The progress bar animating
- The milestone checkbox being ticked
- The "clear all milestones" option

**NOTE:** Milestones are an extra feature that basic goal apps do not have. Showing them makes the video stronger.

---

## [SCENE 10] — The AI Advisor (3:45–4:20)

**ACTION:** Go back to the dashboard and tap the **robot icon** on the green bar.

**SAY (voiceover):**
> "The AI advisor. You can type or you can use the microphone. And it does not give generic advice, it uses your own numbers."

**ACTION:**
- Type: `I spend 800 on food every week. How can I cut this to 500?`
- Let the **streamed reply** arrive word by word
- Then ask a **voice** question: `How much money do I have left?`
- **Long press** a reply to get the copy option

**SHOW:**
- The **typewriter effect** as the answer arrives
- **Markdown rendering**, bullets and bold
- The **mic button** working
- The **saved history**, open the chat again and the previous conversation is there

**SAY (voiceover):**
> "Every conversation is saved to your account in Firestore. Change phones and the history is still there."

**NOTE:** This uses Groq's API. The key is read at runtime, not compiled into the code. If the AI does not respond, record this scene again, because the key needs to be in your `.env` file.

---

## [SCENE 11] — The Learning Tab (4:20–4:30)

**ACTION:** Tap **Learning** in the bottom navigation.

**SAY (voiceover):**
> "The Learning tab has financial literacy lessons. An admin publishes them, and if there are no lessons the app does not go blank, it falls back to three built-in ones."

**ACTION:** Open an article, read it, go back.

**SHOW:** The article cards, category tags, and reading time

---

## [SCENE 12] — Profile, Theme, and the Delete Option (4:30–4:50)

**ACTION:** Tap the **person icon** in the top bar.

**SAY (voiceover):**
> "Profile and settings. You can edit your name and phone, change the theme, and a student can delete their own account."

**ACTION:**
- Tap the **Dark to Light theme** toggle and show it switching, the dark theme is true black
- Tap **"Delete my account"**, show the dialog, then tap **Cancel**

**SHOW:**
- The full list in the dialog: transactions, savings goals, profile, notifications, AI chats
- **"Your email is released so it can be registered again"**
- The password field

**IMPORTANT:** Open the dialog and tap **Cancel**. Do not actually delete, because the later scenes need the account. The point of this scene is only to show that the feature exists and that the deletion happens inside the app rather than through an admin. That is an honest design choice, and a reviewer will respect it.

**SAY (voiceover):**
> "Notice that the delete button belongs to the student, not the admin. Firebase will not let an app remove somebody else's sign in, for security reasons. So we took the button away from the admin and gave it to the student."

---

## [SCENE 13] — Privacy Policy and About (4:50–5:00)

**ACTION:** Tap the **three dots** in the top bar, then **About**, then open the Privacy Policy.

**SAY (voiceover):**
> "The privacy policy is written out in full, across nine sections. It is available before you sign in as well. Where the data goes and what is stored, all of it is stated plainly."

**SHOW:** The policy text, scrolling through it

**NOTE:** Keep this scene short. You only need to show that the policy is real, nobody needs to read it.

---

## [SCENE 14] — Admin Overview (5:00–5:20)

**ACTION:** Log out and sign in with an **admin account**, or change a role. The admin panel appears.

**SAY (voiceover):**
> "The admin panel. Live numbers pulled straight from Firestore: total users, students, admins, open queries, total feedback, and articles."

**SHOW:**
- All **six stat cards** at once
- The **recent activity** list

**NOTE:** If you have little real data, create two or three students first. An empty admin panel looks pointless.

---

## [SCENE 15] — Admin: Users (5:20–5:45)

**ACTION:** Tap **Users** in the bottom navigation and open a student.

**SAY (voiceover):**
> "The Users tab. You can search, change a role, promote a student to admin or demote them back, and suspend or restore an account."

**ACTION:**
- **Search** for a student
- Open their profile
- **Change the role** and confirm
- **Suspend**, type a reason, and confirm
- Tap **"Restore access"**

**SHOW:**
- The **reason field** in the suspend dialog, because the reason is shown to the student
- Your own account, where the suspend and role buttons are **disabled**, show this

**IMPORTANT:** There is **no delete button** here. Show that, and connect it to the line from Scene 12. If a reviewer asks, tell them it is a decision rather than a mistake.

**SAY (voiceover):**
> "Notice there is no delete button here. An admin genuinely cannot delete another account, because the email would stay locked and the student could never register again. So we removed that feature rather than ship one that half works."

---

## [SCENE 16] — The Suspended Student View (5:45–5:55)

**ACTION:** Suspend a student, then sign in **as that student**.

**SAY (voiceover):**
> "Here is what a suspension does. This student signs in and gets a full screen lock message, including the reason the admin gave. There is an appeal button that sends a message straight to the admin's inbox."

**SHOW:**
- The **suspended screen** with the reason text
- The **"Contact admin"** button

**IMPORTANT:** The suspended check runs before the role check, so a suspended admin is also locked out. Worth saying out loud.

---

## [SCENE 17] — Admin: Analytics, Learn, Support (5:55–6:15)

**ACTION:** Move through the remaining admin tabs.

**SAY (voiceover):**
> "Analytics shows the percentage breakdown of spending by category. In the Learn tab an admin can publish, edit, and reorder lessons. The Support tab is the inbox of student queries, where you can type and send a reply."

**ACTION:**
- **Analytics**: the category percentages
- **Learn**: add a new article
- **Support**: open a query, tap **Reply**, type an answer, tap **Send reply**

**SHOW:**
- The reply success overlay
- The category percentage list

**NOTE:** Whether the reply saves depends on `firestore.rules` being deployed. Deploy it before you record, otherwise you will show "Reply sent" and it will not actually save.

---

## [SCENE 18] — End Screen (6:15–6:25)

**ACTION:** Show the best looking screen, the dashboard in dark theme with data in it, then an end card.

**SAY (voiceover):**
> "PennyPal. A student budgeting app built with Flutter and Firebase, running on Android, iOS, and web. Thank you."

**SHOW:** An end card with the app name and the tech stack: Flutter, Firebase, Groq AI

---

## Flow at a Glance (Recording Order)

```
1.  Splash and onboarding, six slides
2.  Sign up and the privacy policy link
3.  Guided tour, needs a fresh empty account   <- record separately
4.  Dashboard and the View All buttons
5.  Add a transaction with a receipt
6.  Notifications
7.  Transactions: search, filter, swipe to delete
8.  Budget, set a limit, the warning
9.  Savings goals and milestones
10. AI advisor: typing, voice, and history
11. Learning tab
12. Profile, theme, the delete dialog
13. Privacy policy
14. Admin overview, six stat cards
15. Admin users: search, role, suspend
16. The suspended student view
17. Admin analytics, learn, support
18. End screen
```

**18 scenes, roughly 6 minutes**

---

## Shooting Tips

| Tip | Why |
|---|---|
| Record every scene twice | The first is practice, the second is the keeper |
| Do not zoom | The phone's native resolution looks best |
| Record in dark theme | It is true black and looks premium on screen |
| Wait for loading spinners | Let the data load, never show an empty list |
| Show the notification tray | Scroll down, the system notification is there |
| Record the voiceover afterwards | Shoot the video first, then add audio. Syncing is far easier |

---

## Common Mistakes

| Mistake | What it costs you |
|---|---|
| Recording with an empty app | A reviewer needs to see data within the first five seconds |
| Forgetting to set a budget | The dashboard ring has nothing to show |
| Having no students for the admin panel | It shows zero users and the feature does not land |
| Not attaching a receipt | That whole feature is missed |
| Not tapping Cancel in the delete dialog | The account is gone and every later scene breaks |
| Using an old account for the tour scene | The tour will not appear and you will be describing something that is not on screen |
| Sending a reply when the rules are not deployed | It looks like replies do not work |

---

## Optional: a Two Minute Version

Keep only these, scenes **1, 2, 5, 8, 9, 10, 12, 18**.

- Scene 1: onboarding, what the app is
- Scene 2: sign up
- Scene 5: transaction with a receipt
- Scene 8: budget and the warning
- Scene 9: goals and milestones
- Scene 10: the AI advisor
- Scene 12: profile and the delete dialog, including the line about the admin not having it
- Scene 18: end screen

Cut everything else. That covers the whole app in two minutes and still hits every point that matters.
