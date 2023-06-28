# Copyright (c) [2020-2023] SUSE LLC
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
require "y2storage/encrypt_password_checker"

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
        Yast.import "ProductFeatures"
        Yast.import "Report"

        @passwd_checker = Y2Storage::EncryptPasswordChecker.new
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

        HSquash(
          VSquash(
            VBox(
              MinWidth(60, MinHeight(10, RichText(description_text))),
              VSpacing(2),
              passwd_widget(:passphrase, _("Encryption Passphrase")),
              passwd_widget(:repeat_passphrase, _("Verify Passphrase")),
            )
          )
        )
      end

      # @return [String]
      def help_text
        _(
          "<p>When installing SUSE Linux Enterprise in the Common Criteria evaluated " \
          "configuration, some restrictions apply to available configuration options.</p>\n" \
          "<p>Please refer to the deployment guide before proceeding.</p>\n" \
          "<p>Common Criteria demands all file systems to be encrypted. The passphrase " \
          "entered here will be used by default for encrypting devices in the partitioning " \
          "Guided Setup. That includes the initial partitioning proposal automatically " \
          "calculated by the installer.</p>\n" \
          "<p>Notice that you will have to enter the correct password each time you boot " \
          "the system. So make sure to not lose it!</p>"
        )
      end

      # Handler for the 'next' event (button)
      def next_handler
        return unless valid?

        # put libgcrypt into FIPS mode. libstorage-ng calls the cryptsetup
        # external command so this takes effect when formatting luks volumes.
        # Needs to happen in instsys. The target system boots with fips=1 kernel
        # command line so this setting is not needed.
        Yast::WFM.Execute(Yast::Path.new(".local.mkdir"), "/etc/gcrypt")
        Yast::WFM.Write(Yast::Path.new(".local.string"), "/etc/gcrypt/fips_enabled", "1")

        write_passphrase

        super
      end

      protected

      # @return [Y2Storage::EncryptPasswordChecker]
      attr_reader :passwd_checker

      # Introductory text to explain how the role works
      #
      # @return [String]
      def description_text
        _(
          "<p>Please refer to the deployment guide before proceeding with the " \
          "installation of this Common Criteria evaluated configuration.</p>\n" \
          "<p>Enter a passphrase below to be used by default when encrypting devices " \
          "during system installation.</p>\n" \
          "<p>Read Help for more details.</p>\n"
        )
      end

      # @return [Yast::Term] ui content for dialog
      def passwd_widget(id, label)
        Password(Id(id), Opt(:hstretch), label, proposal_features["encryption_password"] || "")
      end

      # Whether the information entered in the form is acceptable
      #
      # @return [Boolean]
      def valid?
        valid_passphrase? && good_passphrase?
      end

      # @see #valid?
      def valid_passphrase?
        msg = passwd_checker.error_msg(widget_value(:passphrase), widget_value(:repeat_passphrase))
        return true if msg.nil?

        Yast::Report.Warning(msg)
        false
      end

      # @see #valid?
      #
      # User has the last word to decide whether to use a weak passphrase.
      def good_passphrase?
        message = passwd_checker.warning_msg(widget_value(:passphrase))
        return true if message.nil?

        popup_text = message + "\n\n" + _("Really use this passphrase?")
        Yast::Popup.AnyQuestion(
          "",
          popup_text,
          Yast::Label.YesButton,
          Yast::Label.NoButton,
          :focus_yes
        )
      end

      # Helper to get the value of the given widget
      def widget_value(id)
        Yast::UI.QueryWidget(Id(id), :Value)
      end

      # Writes the entered passphrase into the default storage proposal settings
      def write_passphrase
        proposal = proposal_features
        proposal["encryption_password"] = widget_value(:passphrase)
        log.info "Writing CC passphrase at default storage proposal settings"
        Yast::ProductFeatures.SetFeature("partitioning", "proposal", proposal)
      end

      # Definition of the storage proposal in the product features
      #
      # @return [Hash]
      def proposal_features
        section = Yast::ProductFeatures.GetFeature("partitioning", "proposal")

        # If there is no proposal section (for example, not really running the dialog during
        # installation), proposal may be an empty string here
        section.empty? ? {} : section
      end
    end
  end
end
