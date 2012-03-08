window.addEvent('domready', function() {

    var status = {
        'true': 'open',
        'false': 'close'
    };

    // -- vertical

    var myVerticalSlide = new Fx.Slide('vertical_slide');

    document.id('v_toggle').addEvent('click', function(event){
        event.stop();
        myVerticalSlide.toggle();
    });

});
