var World = {

    init: function initFn() {
        this.createOverlays();
    },

    createOverlays: function createOverlaysFn() {
        /*
            First a AR.TargetCollectionResource is created with the path to the Wikitude Target Collection(.wtc) file.
            This .wtc file can be created from images using the Wikitude Studio. More information on how to create them
            can be found in the documentation in the TargetManagement section.
            Each target in the target collection is identified by its target name. By using this
            target name, it is possible to create an AR.ImageTrackable for every target in the target collection.
         */
        this.targetCollectionResource = new AR.TargetCollectionResource("assets/tracker_leg_arm.wtc", {
            onError: World.onError
        });

        /*
            This resource is then used as parameter to create an AR.ImageTracker. Optional parameters are passed as
            object in the last argument. In this case a callback function for the onTargetsLoaded trigger is set. Once
            the tracker loaded all of its target images this callback function is invoked. We also set the callback
            function for the onError trigger which provides a sting containing a description of the error.
         */
        this.tracker = new AR.ImageTracker(this.targetCollectionResource, {
            maximumNumberOfConcurrentlyTrackableTargets: 3, // a maximum of 5 targets can be tracked simultaneously
            onTargetsLoaded: World.showInfoBar,
            onError: World.onError,
            extendedRangeRecognition: AR.CONST.IMAGE_RECOGNITION_RANGE_EXTENSION.ON,
            //onDistanceChangedThreshold: 0,
            onRotationChangedThreshold: 0,


        });

        /*
            The next step is to create the augmentation. In this example an image resource is created and passed to the
            AR.ImageDrawable. A drawable is a visual component that can be connected to a Trackable
            (AR.ImageTrackable, AR.InstantTrackable or AR.ObjectTrackable) or a geolocated object (AR.GeoObject). The
            AR.ImageDrawable is initialized by the image and its size. Optional parameters allow for transformations
            relative to the recognized target.
        */

        /* Create overlay for page one of the magazine. */
        var imgOne = new AR.ImageResource("assets/imageOne.png", {
            onError: World.onError
        });
        var overlayOne = new AR.ImageDrawable(imgOne, 1, {
            translate: {
                x: -0.15
            }
        });

        var imgTwo = new AR.ImageResource("assets/imageTwo.png", {
            onError: World.onError
        });
        var overlayTwo = new AR.ImageDrawable(imgTwo, 0.5, {
            translate: {
                x: 0.12,
                y: -0.01
            }
        });

        /*
            This combines everything by creating an AR.ImageTrackable with the previously created tracker,
            the name of the image target and the drawable that should augment the recognized image.

            Important: If you replace the tracker file with your own, make sure to change the target name accordingly.
            Use a specific target name to respond only to a certain target or use a wildcard to respond to any or a
            certain group of targets.
        */
        this.pageOne = new AR.ImageTrackable(this.tracker, "*", {
//             drawables: {
//                 cam: overlayOne
//             },
            onImageRecognized: function(target) {

                AR.platform.sendJSONObject({
                    action: "get_data",
                    name: target.name
                });

                var imgOverlay = new AR.ImageResource("assets/" + target.name + ".png", {
                    onError: World.onError
                });

                var translateX = 0.0;
                var translateY = 0.0
                var scale = 0.75;

                if (target.name === 'image_body'){
                    translateX = -0.50;
                    translateY = 0.30;
                    scale = 0.25
                }
                else if (target.name === 'image_lower_arm'){
                    scale = 2
                }
                else if (target.name === 'image_upper_arm'){
                    scale = 2
                }
                var overlay = new AR.ImageDrawable(imgOverlay, 1, {
                    translate: {
                        x: translateX,
                        y: translateY
                    },
                    scale: scale
                });

                this.addImageTargetCamDrawables(target, overlay);


                if(target.name === "image_thigh" || target.name ==="image_body"){

                    target.onRotationChanged = function(rotation, destinationTarget) {
                        var translation = target.getTranslationTo(destinationTarget);
                        //if(target.name.localeCompare("image_knee")){
                            AR.platform.sendJSONObject({
                                action: "get_data",
                                name: destinationTarget.name,
                                data: [rotation.x, rotation.y, rotation.z, translation.x, translation.y, translation.z]
                            });
                            //World.updateDistanceToTarget(rotation.z);

                        //}


                    }
                }


                // World.hideInfoBar();

            },

            onError: World.onError,

        });

        /*
            Similar to the first part, the image resource and the AR.ImageDrawable for the second overlay are created.
        */


        /*
            The AR.ImageTrackable for the second page uses the same tracker but with a different target name and the
            second overlay.
        */

        /*
        this.pageTwo = new AR.ImageTrackable(this.tracker, "jatz*", {
            drawables: {
                cam: overlayTwo
            },
            onImageRecognized: World.hideInfoBar,
            onError: World.onError
        });
        */
    },
//    captureScreen: function captureScreenFn() {
//        AR.platform.sendJSONObject({
//            action: "get_data"
//        });
//    },

    updateDistanceToTarget: function updateDistanceToTargetFn(distance) {
        document.getElementById('distanceDisplay').innerHTML = "Distance from target: " + distance + " cm";
    },

    onError: function onErrorFn(error) {
        alert(error);
    },

    // hideInfoBar: function hideInfoBarFn() {
    //     document.getElementById("infoBox").style.display = "none";
    // },

    showInfoBar: function worldLoadedFn() {
        // document.getElementById("infoBox").style.display = "table";
        document.getElementById("loadingMessage").style.display = "none";
    }
};

World.init();