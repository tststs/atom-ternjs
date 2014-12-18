var TSTSTS = function () {

    var that = this;

    this.$document = $(document);
    this.obj = {

        foo: 1,
        bar: 2
    };
    this.arr = [1, 2, 3];
    this.str = 'foo';

    this.init = function () {

        this.$document.on('docContentAppended', function (e) {

            that.registerHandler(e.target);
        });

        this.registerHandler(this.$document);
    };

    this.registerHandler = function ($context) {

        return false;
    };
};
