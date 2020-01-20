# Automated Dynamic Graphics Using External Datasource With Cinegy Air / Playout

DRAFT

## Introduction

A frequent requirement of customers is to use dynamic elements inside on-screen graphics. At Cinegy, we use the Cinegy Titler engine to render real-time graphics elements for compositing into the output from a Cinegy Playout engine. This engine has a lot of powerful features - as well as being a real-time optimized graphics system, it also supports binding of elements within a graphics scene to imported variables.

Customers can update variables within the Cinegy Air or Cinegy CG operator panels, allowing injection and updating of elements on-the-fly - for example, to caption the name of a person appearing on-screen, or to provide some values for a weather forecast graphic. These could be injected via 'traffic' integration when the rest of the playlist is composed, or entered by operators under instruction from a director in a gallery.

However, sometimes customers don't want to provide data ahead of time into the operator panels - they would rather delegate fulfilment of these variables to some controller that could just make sure that up-to-date values are prepared and injected into the engine ahead of time.

This post focusses on one way that this can be achieved simply through binding to the playout engine EPG event system and then using a PowerShell script to read from a trivial example data source which then ensures those values are made available to the engine.

## Cinegy Playout & The Variable 'Postbox'

There is a concept inside of the universal playout engine we use called informally the 'postbox'. You can use this postbox to ask the engine to use new values for any graphics scenes. The mechanisms can be considered analogous to writing something on a postcard, and then dropping it into a mailbox - the engine will read your postcard, and copy whatever you have written on this into the value for the variable corresponding to the 'address' on the postcard.

There are a few rules about the postbox that are worth considering:

- The last value assigned to a variable 'wins' and becomes the current value
- The postbox is a 'dead drop'; once you drop a something in, you can't change your mind and pull it back out
- The postbox will hold values regardless of if a corresponding scene is actively using those values

It is the last element that can catch people out, although at the same time we will use this to our advantage to meet our needs. It is actually a very useful and powerful capability to be able to set variable values up ahead-of-time and not worry about the relationship to whatever might be currently rendering - but it also means that you need to be careful that variable names are unique if you want them to be isolated. 

For example, it might make perfect sense that a variable for the outside temperature is a globally shared variable - all templates that render can just use that variable and the results would be as expected. However, an item-specific value - maybe the description strap of a caption for a person - could easily cause problems if a variable with a trivial name like 'description' were used. You have been warned!

If you want to see technical details regarding the operations you can carry out via the postbox, or how to see how to carry out such operations, please see the following resources for documentation and examples:

CINEGY OPEN AND GITHUB LINKS HERE

## Triggering Collection

Having established that we wish to put variables for use into the 'postbox' for the engine to use in rendering - we come to the second problem; how to know what values to collect?

Ideally, we would want some form of selective update - so we don't gather every possible variable value, but instead select some specific values and update these at an appropriate moment. We would also want some reliable mechanism to carry out this, preferably simple to set up and with some easy way to see diagnostics. We would also want this to work properly in an high-availability (H/A) setup - so that we don't introduce any single points of failure.

The answer is to use the Cinegy Event Manager service to host the collection, either as a full plugin or as the hosting engine for a PowerShell script. Since explaining how to create a complete Event Manager plugin will take quite a while, we will focus on the latter option - using Event Manager to host a PowerShell script.

Event Manager can run locally to the machine hosting Air Engines, or centrally. Since we want to have the least amount of configuration for this post, and since running locally provides a trivial way to provide H/A (just set up the Event Manager on both Air Engines in a cluster) we will just consider running locally - but the principles will be the same if we had chosen remote hosting.

To start, we shall make a new PowerShell script, using the GitHub hosted reference example script as the basis for our new script - you can get this script here:

[GITHUB LINK]

The Event Manager configuration is incredibly simple in this case - just 'activate' the PowerShell plugin in side Event Manager configuration, and point it at the reference script. Please note, you will need to have an up-to-date PowerShell version installed on your machine (we built and tested this with the latest v5 engine available at time of writing), and you will need to make sure that you have either signed your script or selected an appropriate ExecutionPolicy for your machine. You can read more about Execution Policies here - please also remember that current Event Manager is a 32-bit application, so you will need to set the policy for the 32-bit copy of PowerShell!

[PowerShell execution policies link here]

Now we have a solid mechanism to host an activity based on PowerShell, we need some way to reliably trigger that activity as well as provide some input to that activity that would allow us to understand what data we might need to provide. For this, we are going to hook into events the engine raises that are labelled 'EPG events' in the configurator. Events defined in this tab will be raised either by a timer every X second, or as a result of a change of status on the engine (e.g. when the on-air item changes). These events will be raised always, and regardless of if any other controllers such as the Air or CG panels are connected. You can read more about the specifics of these panels in the manual here:

[Link to manual page]

You can also read about the principle behind this, and the predecessor to this set of events (the subtitling events) in these links related to configuring a subtilting service - it's exactly the same principle, but for on-screen rendering rather than for closed-captions.

We can use the 'command' and 'op1' fields to set arbitrary values related to the configuration that will call this event - which we will use to pick what engine to target with data and to provide a quick sanity check that someone has loaded an appropriate script into Event Manager for the task we expect. You can see a screenshot of a suitable configuration below:

[picture here of set-up tab]

As detailed links above, the system will fill in the 'op2' field with handy XML that describes what is on-air, and what is going to be on air soon - the perfect information for helping process appropriate data variables that will be used soon.

## Putting it together

We have now identified and configured the mechanisms for the following topics:

- Defining regularly firing events that react to changes in playout
- Providing a target for these events in a reliably hosted manner
- Collecting details about what is on-air, and what will soon be on-air
- Collecting details about where to direct any output from the process

Given that we now know what to do, we get reminded with frequency to do it and we get told where to put our work - we just need to focus on doing some work!

For a simple demonstration, and to avoid getting side-tracked by any particular complex data collection, we are going to assume that there is are simple CSV files that will be updated regularly in a folder, and that we will use these files as sources of variables. At this point, we move into pure PowerShell to carry out these actions. Let's list out the steps we need to take within the script:

- Load the script, perform start-up housekeeping (reading inputs, setting up the logger)
- Interpretting the provided XML input to understand what is on-air and cued
- Looking for any matching data file sources for any items by their IDs
- Reading the values from these data sources and organizing them
- Composing a 'postbox' message and sending the message to the engine

The complete script can be accessed here, and it is likely to be polished and adapted as we evolve the product so it might drift a little from the code shown below:

[link to github for script]

Let's now go through each funciton block described above, highlighting snips from the PowerShell script.

### Housekeeping & Setup

### Interpretting Input Values and XML

### Finding Data Sources

### Reading Data & Organizing

### Composing A 'Postbox' Message

