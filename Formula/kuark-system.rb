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
  end

  def post_install
    kuark_home = Pathname.new(Dir.home)/".kuark"
    claude_home = Pathname.new(Dir.home)/".claude"

    # Create symlink ~/.kuark -> Homebrew prefix
    if kuark_home.exist?
      if kuark_home.symlink?
        kuark_home.delete
      else
        kuark_home.rename("#{kuark_home}.backup.#{Time.now.to_i}")
        opoo "Existing ~/.kuark backed up to ~/.kuark.backup.*"
      end
    end
    kuark_home.make_symlink(prefix)

    # Ensure Claude directories exist
    claude_home.mkpath
    (claude_home/"memory"/"kuark").mkpath

    # Inject CLAUDE.md
    marker_start = "<!-- KUARK-SYSTEM-START -->"
    marker_end = "<!-- KUARK-SYSTEM-END -->"
    claude_md = claude_home/"CLAUDE.md"
    kuark_claude_md = prefix/"CLAUDE.md"

    if kuark_claude_md.exist?
      kuark_section = <<~EOS
        #{marker_start}
        # Kuark Universal Development System (Auto-injected via Homebrew)
        # Source: ~/.kuark/CLAUDE.md | Do not edit between markers
        # Update: brew upgrade kuark-system | Remove: brew uninstall kuark-system

        #{kuark_claude_md.read}
        #{marker_end}
      EOS

      if claude_md.exist?
        content = claude_md.read
        if content.include?(marker_start)
          # Replace existing section
          content.sub!(/#{Regexp.escape(marker_start)}.*?#{Regexp.escape(marker_end)}/m, kuark_section.strip)
          claude_md.write(content)
        else
          claude_md.append_lines(["", kuark_section])
        end
      else
        claude_md.write(kuark_section)
      end
    end

    # Merge hooks into settings.json
    hooks_source = prefix/".claude-hooks.json"
    settings_file = claude_home/"settings.json"

    if hooks_source.exist?
      if settings_file.exist?
        system "jq", "-s",
          '(.[0] // {}) as $e | (.[1] // {}) as $k |
           $e * { hooks: (($e.hooks // {}) as $eh | ($k.hooks // {}) as $kh |
           (($eh | keys) + ($kh | keys)) | unique | map(. as $key |
           (($eh[$key] // []) + ($kh[$key] // [])) | {($key): .}) | add // {}) }',
          settings_file, hooks_source,
          out: "#{settings_file}.tmp"
        if File.size?("#{settings_file}.tmp")
          FileUtils.mv("#{settings_file}.tmp", settings_file)
        else
          FileUtils.rm_f("#{settings_file}.tmp")
        end
      else
        system "jq", '{ hooks: .hooks }', hooks_source, out: settings_file.to_s
      end
    end

    ohai "Kuark System installed! Start Claude Code in any project."
    ohai "Say 'proje baslat' to begin a new project."
  end

  def caveats
    <<~EOS
      Kuark Universal Development System has been installed.

      ~/.kuark -> #{prefix}

      Usage:
        Start Claude Code in any project directory.
        The swarm system will auto-initialize.
        Say 'proje baslat' to begin a new project.

      16 AI agents | 10 skill modules | Swarm protocol

      Manual commands:
        Status:  bash ~/.kuark/hooks/swarm.sh status
        Update:  brew upgrade kuark-system
        Remove:  brew uninstall kuark-system
    EOS
  end

  test do
    assert_predicate prefix/"CLAUDE.md", :exist?
    assert_predicate prefix/"agents"/"product-owner"/"SKILL.md", :exist?
    assert_predicate prefix/"agents"/"ui-ux-designer"/"SKILL.md", :exist?
    assert_predicate prefix/"hooks"/"swarm.sh", :exist?
    assert_predicate prefix/"hooks"/"init.sh", :exist?

    # Verify agent count
    agent_count = Dir.glob(prefix/"agents"/"*").count { |f| File.directory?(f) }
    assert_equal 16, agent_count
  end
end
