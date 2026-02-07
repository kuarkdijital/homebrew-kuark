class KuarkSystem < Formula
  desc "Multi-agent AI development system for Claude Code"
  homepage "https://github.com/kuarkdijital/kuark-system"
  url "https://github.com/kuarkdijital/kuark-system/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "c94717580e024ee7a1bd4d5b61669a0e5246d9d1690236966499c4073df9a5bd"
  license "MIT"

  depends_on "jq"

  def install
    # Install all kuark-system files to the prefix
    prefix.install Dir["*"]
    prefix.install Dir[".*"].reject { |f| %w[. .. .git .github].include?(File.basename(f)) }

    # Make hooks executable
    (prefix/"hooks").glob("*.sh").each { |f| f.chmod 0755 }

    # Install bin/kuark-setup from repo (already has correct shebang + executable)
    bin.install prefix/"bin"/"kuark-setup"
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
