# Hactive

Hactive a fully operational iOS application that extracts heart rate data from Apple’s smart-watches to construct heart rate profiles of an individual.

## Getting Started

### Prerequisites

1. To collect heart rate data you will need access to an Apple Watch.
2. Hactive requires an iOS device to operate.

### Installing

1. Clone this repository.
2. Open the `.xcodeproj` file in Xcode.
3. Run the application.


## How it works

### User flow

Record workouts on your Apple watch using the default workout application.
![Alt text](img/workout.png?raw=true "Workout type")

Both running and walking type workouts are compatible with Hactive since these workouts also record GPS activity. 
![Alt text](img/indoor-run.png?raw=true "Workout type")

Open Hactive application on your iPhone to view the list of workouts. Select a workout to see a detailed graphical view along with the associated heart rate dynamic profiles.

Add a title and a description of the workout along with the age and weight of the person who's workout this belongs to.

Age and weight are used to determine the HRDP's of each workout. If no value is set, Hactive will take the values stored in Apples health app. Failing that, it will default to `age = 60` and `weight = 60kg`. 

If you are using this application as a researcher you will need to enter the details of the user corresponding to each workout. If however, you are using the application for personal use, simple set this data once in the Apple's health application.  

The data can be exported as a CSV file.

![Alt text](img/labelling-data.png?raw=true "Labelling Data")

### Calculating HRDP

One of the biggest challenges in constructing reliable heart rate profiles from heart rate data in a free-living environment is that it is difficult to accurately identify periods of physical activities from the long, and possibly noisy, continuous monitoring time series data. In our previous work, we used the GPS and time data to estimate a person’s physical movement and therefore their energy expenditure (EE). This works well when the person is subjected to prescribed activities that involve physical displacement such as stair-climbs and running. How- ever, this EE approach does not capture stationary physical exertions such as weight-lifting, jumping and running on a treadmill. Also, the EE approach rely on good GPS data, which may be limitation in areas or devices due to inaccurate GPS data.

To circumvent the problems with using EE to identify periods of physical activities, we developed an alternative approach that relies on the patterns in the heart rate time series alone. The first step of this new method was to find a time threshold of twenty seconds in which BPM was strictly non- decreasing. We then established two criteria by which we can assess if this period reflects the beginning of a HR profile.

1. If the final recorded BPM at the end of that twenty- second period was greater than 50% of that individual’s
maximum possible heart rate, it was a sign that they
were in a medium to high-intensity exercise zone.
2. The second criterion is to take the percentage difference of an individual’s heart rate from the beginning to the end of that time threshold. A 10% percentage increase was reflective of an individual beginning some form of exercise and therefore was an appropriate threshold. As there was no historical to determine this threshold, this value was modified appropriately while testing.

Once both of these criteria were met, we marked the beginning of the HR profile. This was graphically represented as a series of alternating red and black dots, each set reflecting a different HR profile. It is important to note that if one of these criteria failed, we did not discard the zone entirely but rather increased the span of the zone we were analysing. For instance, if we were looking at a random period of twenty strictly non-decreasing BPM recordings, that did not meet the criteria, we increase the zone to twenty-one seconds and so on until the criteria was met or the zone began decreasing. This accounts for the fact that a user’s BPM may be increasing gradually and it takes more than twenty seconds to pass our ‘user is-active’ threshold.

Once all the HR profiles have been extracted, Hactive can scale the profile down to 100-second time series. These scaled profiles can then be displayed in a single plot. This allows for a visual comparison of all the HR profiles. Furthermore, Hactive computes statistical summaries of the HR profiles such has maximum HR found in a profile.

![Alt text](img/hrdp.png?raw=true "HRDP")

### Data management

HRDP are not persisted. They are constructed every time you view a workout and destroyed when you exit the view workout page. This means most of the computation is done when viewing each individual workout. The only data that is persisted is the label, description, age and weight entered by the user. 

The app is optimised to use Apple's existing data infrastructure (iOS persistent datastore). This means privacy and security is handled by Apple. Hactive access this data through Apple HealthKit (https://developer.apple.com/health-fitness/).

We have utilised the Swifts Core Data framework which is used to manage the model layer object of Hactive. In general, Core Data is a persistent data management tool for the model layer objects of an iOS application. In the case of this application, it was used to store the labelling data inputted by the user on the activity page. Through this feature, users are provided with the ability to title their workouts, rate how intensive it was (from a scale zero to ten) and provide any extra detail about their workout. This mechanism provides researchers with labelled data for future potential machine learning algorithms. Having a strenuous rating, for example, allows researchers to model and compare workouts of the same intensity. Furthermore, should researchers require the users of Hactive to provide any other relative health information, such as current fitness level and proneness to heart problems, they can provide this information by saving it with Core Data.

Swift has a medically orientated API ‘ResearchKit’, which was designed to support researchers and clinicians in conduct- ing studies and collecting sensitive data. This kit allows med- ical researches to embed consent flows, surveys and real-time dynamic, active tasks into an application. A template consent form has been installed in Hactive to allow future researchers to incorporate their own approved consent document once one is created. Like ResearchKit, HealthKit was developed to manage, monitor and safely store sensitive medical health data. To avoid the management of sensitive data such as heart rate, Hactive has offloaded this to HealthKit (https://developer.apple.com/health-fitness/). By making fetch requests to HealthKit rather than storing the data within the application, we avoid managing the massive data pile that will inevitably build up as a result of recording and storing workouts as well as the security risks associated with this data 

As a simple evaluation, we recorded twenty-five workouts, which were stored in HealthKit on a test mobile device. Extraction of all these workouts from HealthKit took an average of 0.15 seconds. Of the twenty-five workouts, the average length is twenty-seven minutes. To load a single workout of this length takes 0.5 seconds. The longest workout of 104 minutes, took 4.0 seconds to load, which we attribute to the increase in the number of HRDP extracted during such a lengthy exercise. We are generally comfortable with the runtime performance.

### Consent form

A default consent form is available in the application. Manipulate it for your scientific study.

![Alt text](img/consent-form.png?raw=true "Consent Form")

## Privacy

Hactive takes your privacy very seriously.

## Built With

* [Swift](https://developer.apple.com/documentation/swift) - The programming language used
* [ResearchKit](https://github.com/researchkit/) - For the consent form
* [Charts](https://github.com/danielgindi/Charts/) - Graphical display

## Authors

* **Adam Goldberg** - *Initial work* - [PurpleBooth](https://bitbucket.org/algoadam/)
* **Dr. Joshua Ho** - *Initial work*

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

The work was supported in part by funds from the National Health and Medical Research Council (1105271 to JWKH),
and the National Heart Foundation (100848 to JWKH). We thank Djordje Djordjevic, Andrian Yang and Eleni Giannoulatou for their helpful comments and discussion throughout the study.

