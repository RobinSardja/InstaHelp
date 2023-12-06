# InstaHelp

The fastest hands-free mobile emergency contact solution!

## Inspiration
The InstaHelp team was inspired by the countless members of the community who face greater dangers in the world compared to others, especially, women, children, and the elderly.

## What it does
InstaHelp uses speech detection AI to detect the user’s natural responses to dangerous scenarios. Upon detection, InstaHelp texts the user’s designated emergency contacts with a call for help and a Google Maps link to the GPS location of the user.

## How we built it
We first started building InstaHelp with Picovoice Porcupine Wake Word as our choice of speech detection AI. We trained 2 models, “somebody help” and “someone help me”, to demonstrate InstaHelp’s ability to detect the user’s natural response to dangerous scenarios. Then, we used the Flutter SDK to develop a mobile application compatible with Android and iOS devices from a single codebase, alongside several popular Flutter dependencies to access the user’s contact list and send SMS messages. Finally, we used Google Maps to pinpoint the user’s location and generate a navigation link to send to their emergency contacts.

## Challenges we ran into
Our greatest challenge was perfecting the speech detection model to accurately pick up the user’s calls for help in any situation. From loud screams to get the attention of others nearby to quiet whispers to stay hidden from danger, there were many scenarios our app had to take into consideration before we even started training our model. With attention to every detail, we trained 2 models to mimic 2 possible natural responses to dangerous scenarios: “somebody help” and “someone help me” with the precise detection threshold for the most accurate emergency detection.

Towards the end, we had some compatibility issues between importing phone numbers from the user’s contact list and sending SMS messages to these numbers. The Flutter dependency we used for importing contacts saved the phone numbers of these emergency contacts with the usual formatting of parentheses around the area code and dashes between the exchange code and the line number. The Flutter dependency we used to send texts, however, only accepted phone numbers without any of this formatting. We worked around this by first importing the user’s contacts, then used Regex to remove all nonnumeric characters from the phone number, and then added the number as a recipient.

## Accomplishments that we're proud of
Our greatest accomplishment is creating a faster, more covert, and more accessible emergency contact solution that goes against the use of branded activation phrases and an overdependent reliance on physical user inputs. InstaHelp puts our users first, that’s why we opted against using a branded voice-activation system to detect dangerous scenarios. The InstaHelp team understands that most people in their time of need wouldn’t have the capacity or quick thinking to use branded activation phrases, such as “Hey InstaHelp, call for help!”

These even run the risk of attackers noticing the user’s attempt to contact emergency services with voice activation, potentially reminding the attackers to get rid of or destroy the user’s phone, taking away the user’s last source of communication. We believe that the fastest way for users to reach out to their emergency contacts is by detecting the natural, instinctual responses to dangerous scenarios. And as hands-free solution, InstaHelp works just as well in scenarios where users may have lost ability to make physical user inputs, such as broken arms, and for users with pre-existing conditions, such as paralysis or Parkinson’s disease, making InstaHelp more accessible than solutions that rely on physical inputs.

## What we learned
When it comes to emergencies, InstaHelp knows that every second matters. With this new approach to voice-activated emergency contacts using natural responses, InstaHelp provides a faster, more covert, and more accessible emergency contact solution.

## What's next for InstaHelp
With the highly scalable Picovoice Porcupine Wake Word AI, the InstaHelp team could quickly grow our set of natural responses to dangerous scenarios to ensure our users get help as soon as possible no matter how they respond in their time of need. As the team grows with more team members and more funding, InstaHelp could take advantage of live GPS tracking from Google Maps, providing real-time updates to the victim’s location when they call for help.
