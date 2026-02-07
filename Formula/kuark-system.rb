class KuarkSystem < Formula
  desc "Multi-agent AI development system for Claude Code"
  homepage "https://github.com/kuarkdijital/kuark-system"
  url "https://github.com/kuarkdijital/kuark-system/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "289facb9f563be10572268a450ca6857b2c1d367336caa68e0f9b7e86bca6a85"
  license "MIT"

  depends_on "jq"

  def install
    # Install bin scripts first (before prefix.install moves them)
    bin.install "bin/kuark-setup"

    # Install remaining files to prefix (excluding bin/ which is already handled)
    prefix.install Dir["*"].reject { |f| f == "bin" }
    prefix.install Dir[".*"].reject { |f| %w[. .. .git .github].include?(File.basename(f)) }

    # Make hooks executable
    (prefix/"hooks").glob("*.sh").each { |f| f.chmod 0755 }
  end

  def caveats
    <<~EOS
      Run the setup command to complete installation:

        kuark-setup

      This will:
        - Link ~/.kuark to the Homebrew installation
        - Inject Kuark directives into ~/.claude/CLAUDE.md
        - Configure Claude Code hooks in ~/.claude/settings.json

      After setup, start Claude Code in any project directory.
      Say 'proje baslat' to begin a new project.

      16 AI agents | 10 skill modules | Swarm protocol

      Commands:
        Setup:   kuark-setup
        Status:  bash ~/.kuark/hooks/swarm.sh status
        Update:  brew upgrade kuark-system && kuark-setup
        Remove:  brew uninstall kuark-system
    EOS
  end

  test do
    assert_predicate prefix/"CLAUDE.md", :exist?
    assert_predicate prefix/"agents"/"product-owner"/"SKILL.md", :exist?
    assert_predicate prefix/"agents"/"ui-ux-designer"/"SKILL.md", :exist?
    assert_predicate prefix/"hooks"/"swarm.sh", :exist?
    assert_predicate prefix/"hooks"/"init.sh", :exist?
    assert_predicate bin/"kuark-setup", :exist?

    # Verify agent count
    agent_count = Dir.glob(prefix/"agents"/"*").count { |f| File.directory?(f) }
    assert_equal 16, agent_count
  end
end
