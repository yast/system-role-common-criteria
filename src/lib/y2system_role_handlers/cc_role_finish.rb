# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2020 SUSE LLC
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require "yast"
require "yast2/execute"
require "installation/system_role"
require "installation/services"

module Y2SystemRoleHandlers
  # Implement finish handler for the "cc" role
  class CcRoleFinish
    include Yast::Logger

    def run
      run_cc_scripts
    end

  protected

    # Run the activation script
    def run_cc_scripts
      log.info "Running CC scripts"
      Yast::Execute.on_target("/usr/lib/common-criteria/run")
    end

    # Enable mandatory services
    #def enable_service
    #  ::Installation::Services.enabled |= ["rsyslog", "sshd"]
    #end

    # CC role
    #
    # @return [::Installation::SystemRole,nil] CC role or nil if not defined.
    def role
      ::Installation::SystemRole.find("cc_role")
    end
  end
end
