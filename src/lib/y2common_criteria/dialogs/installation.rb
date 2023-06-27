# Copyright (c) [2020-2022] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "yast"
require "ui/installation_dialog"

# Namespace for code specific to the Common Criteria system role
module Y2CommonCriteria
  # Dialogs for the Common Criteria role
  module Dialogs
    # Main dialog for the Common Criteria system role, to be presented right after the role
    # selection
    class Installation < ::UI::InstallationDialog
      # Constructor
      def initialize
        super
        textdomain "cc"
        Yast.import "UI"
        Yast.import "RichText"
      end

      # @return [String]
      def dialog_title
        _("SUSE Linux Enterprise Common Criteria Evaluated Configuration")
      end

      # @return [Yast::Term] ui content for dialog
      def dialog_content
        entropy = Yast::SCR.Read(
          Yast::Path.new(".target.string"), "/proc/sys/kernel/random/entropy_avail"
        ).to_s
        log.info("entropy #{entropy}")

        display = Yast::UI.GetDisplayInfo
        space = display["TextMode"] ? 1 : 3

        text = _("<p><b>Common Criteria Evaluated Configuration enabled</b></p>") +
          _(
            "<p>When installing SUSE Linux Enterprise in the Common Criteria evaluated configation," \
            "some restrictions apply to available configuration options.\n" \
            "Please refer to the deployment guide before proceeding.\n" \
            "Click <b>Next</b> to continue. </p>\n\n"
          )
        rt =
          if Yast::Builtins.regexpmatch(text, "</.*>")
            RichText(Id(:text), text)
          else
            log.debug "plain text"
            RichText(Id(:text), Opt(:plainText), text)
          end

        VBox(
          VSpacing(space),
          HBox(
            HSpacing(2 * space),
            rt,
            HSpacing(2 * space)
          ),
          VSpacing(2)
        )
      end

      # @return [String]
      def help_text
        _("<p>Click <b>Next</b> to continue.</p>\n")
      end

      # Handler for the 'next' event (button)
      def next_handler
        # for testing to speed things up
        #Yast::Pkg.SetSolverFlags("onlyRequires" => true)

        # put libgcrypt into FIPS mode. libstorage-ng calls the cryptsetup
        # external command so this takes effect when formatting luks volumes.
        # Needs to happen in instsys. The target system boots with fips=1 kernel
        # command line so this setting is not needed.
        Yast::WFM.Execute(Yast::Path.new(".local.mkdir"), "/etc/gcrypt")
        Yast::WFM.Write(Yast::Path.new(".local.string"), "/etc/gcrypt/fips_enabled", "1")
        super
      end
    end
  end
end
