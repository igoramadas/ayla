module.exports = (grunt) ->
    grunt.initConfig
        concat:
            js:
                src: ["www/js/lib/jquery.js", "www/js/lib/jquery.cookie.js", "www/js/lib/lodash.js",
                      "www/js/lib/moment.js", "www/js/lib/modernizr.js", "www/js/lib/placeholder.js",
                      "www/js/lib/fastclick.js", "www/js/lib/foundation.js"]
                dest: "www/js/app_lib.js"
            css:
                src: ["www/css/lib/*.*"]
                dest: "www/css/app_lib.css"

        coffee:
            compileJoined:
                files:
                    "www/js/app.js": ["www/js/*.coffee"]
                options:
                    join: true

        stylus:
            compile:
                files:
                    "www/css/app.css": ["www/css/*.styl"]
                options:
                    compress: true

        watch:
            coffee:
                files: 'www/js/*.coffee'
                tasks: ['coffee']
            stylus:
                files: 'www/css/*.styl'
                tasks: ['stylus']

        concurrent:
            tasks: ['watch:coffee', 'watch:stylus']
            options:
                logConcurrentOutput: true

    grunt.loadNpmTasks 'grunt-contrib-concat'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-stylus'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-concurrent'

    grunt.registerTask 'default', ['concat:js', 'concat:css', 'concurrent']
