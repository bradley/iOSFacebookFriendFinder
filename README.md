Connecting to Facebook and Finding Friends
===========

This project will handle connecting to Facebook using two methods.
First, if the user has connected his or her device to Facebook using the
Social Framework (i.e.; by initiating a Facebook account in their device
settings), the application will attempt to connect via this method. If
the user has not done this, the application uses the Facebook SDK as a
fallback.

There a few things that need to be done in order for this to work with
Facebook.

1. Create a new application at http://developers.facebook.com/apps

2. In the 'Select how your app integrates with Facebook' settings,
expand the 'Native iOS App' section and type in your Bundle ID where it
asks you to do so. For example:

```
yakamoto.FacebookFriends
```

3. Check the radio button in the same section for 'Facebook Login'

4. Follow the instructions in Section #5 here:
https://developers.facebook.com/docs/getting-started/facebook-sdk-for-ios/
