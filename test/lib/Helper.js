var Helper = function () {

    var that = this;
    this.str = '<3';

    /**
    * Returns the love-string
    */
    this.help = function () {

        return this.str;
    };

    /**
    * Description goes here
    * @param {string} a - Any string.
    * @param {number} b - Any number.
    * @param {function} c - Any callback.
    */
    this.exampleMethod = function (a, b, c) {

        c();
        return a + b;
    };
};
