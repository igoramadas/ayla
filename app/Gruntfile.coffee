module.exports = (grunt) ->
    grunt.initConfig
        concat:
            dist:
                src: ["www/js/lib/*.*"]
                dest: "www/js/lib.js"

        coffee:
            compileJoined:
                options:
                    join: true
                files:
                    "www/js/coffee.js": ["www/js/coffee/*.coffee"]

        watch:
            files: 'www/js/coffee/*.coffee'
            tasks: ['coffee', 'concat']

    grunt.loadNpmTasks 'grunt-contrib-concat'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'

    grunt.registerTask 'default', ['watch']
