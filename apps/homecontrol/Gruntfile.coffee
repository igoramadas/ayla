module.exports = (grunt) ->
    grunt.initConfig
        concat:
            js:
                src: ["www/js/lib/jquery.js", "www/js/lib/jquery.cookie.js", "www/js/lib/jquery.colorpicker.js",
                      "www/js/lib/lodash.js", "www/js/lib/moment.js", "www/js/lib/modernizr.js",
                      "www/js/lib/placeholder.js", "www/js/lib/fastclick.js", "www/js/lib/foundation.js",
                      "www/js/lib/crel.js", "www/js/lib/chart.js", "www/js/lib/knockout.js", "www/js/lib/pager.js",
                      "www/js/lib/ko.smartpage.js", "www/js/lib/ko.colorpicker.js"]
                dest: "www/app_lib.js"
            css:
                src: ["www/css/lib/*.*"]
                dest: "www/app_lib.css"

        coffee:
            compileJoined:
                files:
                    "www/app.js": ["www/js/*.coffee"]
                options:
                    join: true

        stylus:
            compile:
                files:
                    "www/app.css": ["www/css/*.styl"]
                options:
                    compress: true

        jade:
            compile:
                files:
                    "www/app.html": ["www/html/index.jade"]
                options:
                    data:
                        debug: true

        watch:
            coffee:
                files: 'www/js/*.coffee'
                tasks: ['coffee']
            stylus:
                files: 'www/css/*.styl'
                tasks: ['stylus']
            jade:
                files: 'www/html/*.jade'
                tasks: ['jade']

        concurrent:
            tasks: ['watch:coffee', 'watch:stylus', 'watch:jade']
            options:
                logConcurrentOutput: true

    grunt.loadNpmTasks 'grunt-contrib-concat'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-stylus'
    grunt.loadNpmTasks 'grunt-contrib-jade'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-concurrent'

    grunt.registerTask 'default', ['concat:js', 'concat:css', 'concurrent']
