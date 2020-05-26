# Hactive

Hactive an iOS application that extracts heart rate data from Apple’s smartwatch to construct heart rate profiles.

## Getting Started

### Installing

Device prerequisites
 * To collect heart rate data you will need access to an Apple Watch with the apple workout app installed.
 * Hactive requires an iOS device to operate.

Software prerequisites and installation
1. Hactive can only run on an Apple Mac computer since it is build with Xcode. Download Xcode from the app store on your Mac (~12gb).
2. The app also uses **Carthage** as it's dependency manager. Install it by opening a terminal and using brew to `brew install carthage` or follow the install guide on [github](https://github.com/Carthage/Carthage).
3. Clone this repository.
2. Open the `.xcodeproj` file in this project (this will open the project in Xcode).
3. Connect your iOS device.
4. Build the application on your iOS device by selecting it as the target device and clicking the play button in the top lefthand corner.
5. Hactive should now be on your iPhone.

## Known Problems

### Reinstall problem

Under Hactive's current implementation, we have decided not to put the app on the app store. As such, when you download and use this application through Xcode, the code-signing tool only validates the app for 7 days. This means that after this period, the app will cease to work and will require you to build it again through Xcode. We understand the inconvenience this causes to the fundamental usability of the application. However, until we decide the app is ready for the app store, this problem will subsist. The silver lining is that because the data is managed by Apple's Health app, the data will persist after the application reinstalls. When this problem occurs, do not uninstall the application but simply connect your device to Xcode and rebuild the app.


### Problems with iOS simulators

This isn't so much a problem but it's important to call out: The iOS simulators on your computer doesn't come with dummy data. This means that although the application will technically work using one of the inbuilt simulators, you won't get the full Hactive experience without data. You'll see that the list of 'past workouts' will be empty. This is why we recommend using an actual iPhone and Apple watch. The Apple watch can collect data from your workouts and only an actual iPhone can read this data since it is stored in the Healthkit app on the iPhone (more on this later).

## How It Works

### User flow

1. Record workouts on your Apple watch using the default workout application. Both running and walking workout types are compatible with Hactive since these workouts also record GPS activity.

![Alt text](img/workout-app.png?raw=true "Apple Watch Workout App")
![Alt text](img/indoor-run.png?raw=true "Indoor Run Workout")

2. Open Hactive application on your iPhone to view the list of workouts. Select a workout to see a detailed graphical view along with the associated heart rate dynamic profiles.

3. Add a title and a description of the workout along with the age and weight of the person who's workout this belongs to. Age and weight are used to determine the HRDP's of each workout. If there is no value set, Hactive will take the values stored in Apple's health app. Failing that, it will default to `age = 60` and `weight = 60kg`.

4. If you are using this application as a researcher you will need to enter the weight and age of each user to their corresponding workout (This can be done by tapping the button `label` on the workout page. If however, you are using the application for personal use, simple set age and weight once in Apple's health application.

5. Exported the data as a CSV file.

![Alt text](img/health-app.png?raw=true "Apple Health App")

### Calculating HRDP

One of the biggest challenges in constructing reliable heart rate profiles from heart rate data in a free-living environment is that it is difficult to accurately identify periods of physical activities from the long, and possibly noisy, continuous monitoring time series data. In our previous work, we used GPS and time data to estimate a person’s physical movement and therefore their energy expenditure (EE). This works well when the person is subjected to prescribed activities that involve physical displacement such as stair-climbs and running. However, this EE approach does not capture stationary physical exertions such as weight-lifting, jumping and running on a treadmill. Also, the EE approach relies on good GPS data, which may can be jeopardised by areas with poor signal (such as indoors) or lower-grade devices.

To circumvent the problems with using EE to identify periods of physical activities, we developed an alternative approach that relies on the patterns in the heart rate time series alone. The first step of this new method was to find a time threshold of twenty seconds in which BPM was strictly nondecreasing. We then established two criteria by which we can assess if this period reflects the beginning of a HR profile.

1. If the final recorded BPM at the end of that twenty-second period was greater than 50% of that individual’s
maximum possible heart rate (estimated as 220 minus one's age), it was a sign that they were in a medium to high-intensity exercise zone. For example, if a person is 60 years of age, their maximum heart rate is ~160BPM and therefore >50% indicates a bpm of 80 - 160.
2. The second criterion is to take the percentage difference of an individual’s heart rate from the beginning to the end of that time threshold. A 10% percentage increase was reflective of an individual beginning some form of exercise and therefore was an appropriate threshold. To take someone 80 years of age; their maximum heart rate is ~140BPM. If their HR started at 60bpm and increased to 75bpm over 20 seconds, their percentage increase is 11% of their maximum, which will breach our threshold. As there was no historical to determine this threshold, this value was modified appropriately while testing.

Once both of these criteria were met, we marked the beginning of the HR profile. This was graphically represented as a series of alternating red and black dots, each set reflecting a different HR profile. It is important to note that if one of these criteria failed, we did not discard the zone entirely but rather increased the span of the zone we were analysing. For instance, if we were looking at a random period of twenty strictly non-decreasing BPM recordings, that did not meet the criteria, we increase the zone to twenty-one seconds and so on until the criteria was met or the zone began decreasing. This accounts for the fact that a user’s BPM may be increasing gradually and it takes more than twenty seconds to pass our ‘user is-active’ threshold.

Once all the HR profiles have been extracted, Hactive can scale the profile down to 100-second time series. These scaled profiles can then be displayed in a single plot to allow for a visual comparison of all the HR profiles. Furthermore, Hactive computes statistical summaries of the HR profiles such has maximum HR found in a profile.

![Alt text](img/hrdp.png?raw=true "HRDP")

### Data management

HRDP are not persisted. They are constructed every time you view a workout and destroyed when you exit the view workout page. This means most of the computation is done when viewing each individual workout. The only data that is persisted is the label, description, age and weight entered by the user.

The app is optimised to use Apple's existing data infrastructure (iOS persistent datastore). This means privacy and security is handled by Apple. Hactive access this data through Apple [HealthKit](https://developer.apple.com/health-fitness/).

We have utilised the Swifts Core Data framework which is used to manage the model layer object of Hactive. In general, Core Data is a persistent data management tool for the model layer object of an iOS application. In the case of this application, it was used to store the labelling data inputted by the user on the activity page. Through this feature, users are provided with the ability to title their workouts, rate how intensive it was (from a scale zero to ten) and provide any extra detail about their workout. This mechanism provides researchers with labelled data for future potential machine learning algorithms. Having a strenuous rating, for example, allows researchers to model and compare workouts of the same intensity. Furthermore, should researchers require the users of Hactive to provide any other relative health information, such as current fitness level and proneness to heart problems, they can provide this information by saving it with Core Data.

Swift has a medically orientated API [ResearchKit](http://researchkit.org/), which was designed to support researchers and clinicians in conducting studies and collecting sensitive data. This kit allows medical researches to embed consent flows, surveys and real-time dynamic, active tasks into an application. A template consent form has been installed in Hactive to allow future researchers to incorporate their own approved consent document once one is created. Like ResearchKit, HealthKit was developed to manage, monitor and safely store sensitive medical health data. To avoid the management of sensitive data such as heart rate, Hactive has offloaded this to HealthKit. By making fetch requests to HealthKit rather than storing the data within the application, we avoid managing the massive data pile that will inevitably build up as a result of recording and storing workouts as well as the security risks associated with this data.

As a simple evaluation, we recorded twenty-five workouts, which were stored in HealthKit on a test mobile device. Extraction of all these workouts from HealthKit took an average of 0.15 seconds. Of the twenty-five workouts, the average length is twenty-seven minutes. To load a single workout of this length takes 0.5 seconds. The longest workout of 104 minutes, took 4.0 seconds to load, which we attribute to the increase in the number of HRDP extracted during such a lengthy exercise. We are generally comfortable with the runtime performance.

### Consent form

A default consent form is available in the application. Manipulate it to suit your scientific study.

![Alt text](img/labelling-data.png?raw=true "Labelling Data")
![Alt text](img/consent-form.png?raw=true "Consent Form")

## Privacy

Hactive takes your privacy very seriously. The data recorded by your Apple watch and managed by Hactive, is secured by Apple. The application makes no network calls and so the data remains safely in your iOS device.

## Built With

* [Swift](https://developer.apple.com/documentation/swift) - The programming language used
* [ResearchKit](https://github.com/researchkit/) - For the consent form
* [Charts](https://github.com/danielgindi/Charts/) - Graphical display

## Authors

* **Adam Goldberg** - *Core development* - [LinkedIn](https://www.linkedin.com/in/goldadamb/)
* **Dr. Joshua W. K. Ho** - *Research idea and supervision*  - [Ho Laboratory](https://holab-hku.github.io/)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

The work was supported in part by funds from the National Health and Medical Research Council of Australia, and the National Heart Foundation of Australia.
