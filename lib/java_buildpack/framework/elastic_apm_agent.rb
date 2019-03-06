# frozen_string_literal: true

# Cloud Foundry Java Buildpack
# Copyright 2013-2018 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch Elastic APM support.
    class ElasticApmAgent < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        print "compile - ElasticApmAgent < JavaBuildpack::Component::VersionedDependencyComponent "
        download_jar
        @droplet.copy_resources
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        print "release - ElasticApmAgent < JavaBuildpack::Component::VersionedDependencyComponent "
        credentials   = @application.services.find_service(FILTER, [SERVER_URL, APPLICATION_PACKAGES])['credentials']
        java_opts     = @droplet.java_opts
        configuration = {}

        apply_configuration(credentials, configuration)
        apply_user_configuration(credentials, configuration)
        write_java_opts(java_opts, configuration)

        java_opts.add_javaagent(@droplet.sandbox + jar_name)
                 .add_system_property('elkapmagent.home', @droplet.sandbox)
        java_opts.add_system_property('elastic.apm.application_packages.enable.java.8', 'true') if @droplet.java_home.java_8_or_later?
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        print "supports? - ElasticApmAgent < JavaBuildpack::Component::VersionedDependencyComponent "
        @application.services.one_service? FILTER, [SERVER_URL, APPLICATION_PACKAGES]
      end

      private

      FILTER = /elasticapm/

      BASE_KEY = 'elastic.apm.'

      SERVER_URL = 'server_urls'

      APPLICATION_PACKAGES = 'application_packages'

      private_constant :FILTER, :SERVER_URL, :APPLICATION_PACKAGES, :BASE_KEY

      def apply_configuration(credentials, configuration)
        configuration['log_file_name']  = 'STDOUT'
        configuration[SERVER_URL] = credentials[SERVER_URL]
        configuration[APPLICATION_PACKAGES] = credentials[APPLICATION_PACKAGES]
        configuration['elastic.apm.service_name'] = @application.details['application_name']
      end

      def apply_user_configuration(credentials, configuration)
        credentials.each do |key, value|
          configuration[key] = value
        end
      end

      def write_java_opts(java_opts, configuration)
        configuration.each do |key, value|
          java_opts.add_system_property("elastic.apm.#{key}", value)
        end
      end

    end

  end
end