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

    # Create the setup script in bin/
    (bin/"kuark-setup").write <<~EOS
      #!/bin/bash
      set -e

      KUARK_PREFIX="#{opt_prefix}"
      KUARK_HOME="$HOME/.kuark"
      CLAUDE_HOME="$HOME/.claude"

      GREEN='\\033[0;32m'
      CYAN='\\033[0;36m'
      YELLOW='\\033[1;33m'
      NC='\\033[0m'

      echo -e "${CYAN}[KUARK]${NC} Setting up Kuark System..."

      # 1. Symlink ~/.kuark -> Homebrew prefix
      if [ -L "$KUARK_HOME" ]; then
          rm "$KUARK_HOME"
      elif [ -d "$KUARK_HOME" ]; then
          BACKUP="$KUARK_HOME.backup.$(date +%s)"
          mv "$KUARK_HOME" "$BACKUP"
          echo -e "${YELLOW}[WARN]${NC} Existing ~/.kuark backed up to $BACKUP"
      fi
      ln -sfn "$KUARK_PREFIX" "$KUARK_HOME"
      echo -e "${GREEN}[OK]${NC} ~/.kuark -> $KUARK_PREFIX"

      # 2. Ensure Claude directories
      mkdir -p "$CLAUDE_HOME"
      mkdir -p "$CLAUDE_HOME/memory/kuark"

      # 3. Inject CLAUDE.md
      MARKER_START="<!-- KUARK-SYSTEM-START -->"
      MARKER_END="<!-- KUARK-SYSTEM-END -->"
      CLAUDE_MD="$CLAUDE_HOME/CLAUDE.md"
      KUARK_CLAUDE_MD="$KUARK_PREFIX/CLAUDE.md"

      # Build the kuark section in a temp file to avoid awk multi-line issues
      SECTION_TMP=$(mktemp)
      {
          echo "$MARKER_START"
          echo "# Kuark Universal Development System (Auto-injected via Homebrew)"
          echo "# Source: ~/.kuark/CLAUDE.md | Do not edit between markers"
          echo "# Update: brew upgrade kuark-system && kuark-setup | Remove: brew uninstall kuark-system"
          echo ""
          cat "$KUARK_CLAUDE_MD"
          echo "$MARKER_END"
      } > "$SECTION_TMP"

      if [ -f "$KUARK_CLAUDE_MD" ]; then
          if [ -f "$CLAUDE_MD" ]; then
              if grep -q "$MARKER_START" "$CLAUDE_MD" 2>/dev/null; then
                  # Extract before and after marker sections, insert new content
                  {
                      sed -n "1,/^$MARKER_START/{ /^$MARKER_START/!p; }" "$CLAUDE_MD"
                      cat "$SECTION_TMP"
                      sed -n "/^$MARKER_END/,\${ /^$MARKER_END/!p; }" "$CLAUDE_MD"
                  } > "$CLAUDE_MD.tmp"
                  mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
                  echo -e "${GREEN}[OK]${NC} CLAUDE.md updated (existing section replaced)"
              else
                  echo "" >> "$CLAUDE_MD"
                  cat "$SECTION_TMP" >> "$CLAUDE_MD"
                  echo -e "${GREEN}[OK]${NC} CLAUDE.md updated (section appended)"
              fi
          else
              cp "$SECTION_TMP" "$CLAUDE_MD"
              echo -e "${GREEN}[OK]${NC} CLAUDE.md created"
          fi
      fi
      rm -f "$SECTION_TMP"

      # 4. Merge hooks into settings.json
      HOOKS_SOURCE="$KUARK_PREFIX/.claude-hooks.json"
      SETTINGS_FILE="$CLAUDE_HOME/settings.json"

      if [ -f "$HOOKS_SOURCE" ]; then
          if [ -f "$SETTINGS_FILE" ]; then
              if grep -q "kuark" "$SETTINGS_FILE" 2>/dev/null; then
                  CLEANED=$(jq '
                      if .hooks then
                          .hooks |= with_entries(
                              .value |= map(
                                  .hooks |= map(select(.command | test("kuark") | not))
                              ) | map(select(.hooks | length > 0))
                          )
                      else . end
                  ' "$SETTINGS_FILE" 2>/dev/null || cat "$SETTINGS_FILE")
                  echo "$CLEANED" > "$SETTINGS_FILE.tmp"
                  mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
              fi

              jq -s '
                  (.[0] // {}) as $e | (.[1] // {}) as $k |
                  $e * { hooks: (($e.hooks // {}) as $eh | ($k.hooks // {}) as $kh |
                  (($eh | keys) + ($kh | keys)) | unique | map(. as $key |
                  (($eh[$key] // []) + ($kh[$key] // [])) | {($key): .}) | add // {}) }
              ' "$SETTINGS_FILE" "$HOOKS_SOURCE" > "$SETTINGS_FILE.tmp" 2>/dev/null

              if [ -s "$SETTINGS_FILE.tmp" ]; then
                  mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
                  echo -e "${GREEN}[OK]${NC} Hooks merged into settings.json"
              else
                  rm -f "$SETTINGS_FILE.tmp"
                  jq --argjson hooks "$(jq '.hooks' "$HOOKS_SOURCE")" '.hooks = $hooks' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" 2>/dev/null
                  mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
                  echo -e "${GREEN}[OK]${NC} Hooks added to settings.json"
              fi
          else
              echo '{}' | jq --argjson hooks "$(jq '.hooks' "$HOOKS_SOURCE")" '. + {hooks: $hooks}' > "$SETTINGS_FILE"
              echo -e "${GREEN}[OK]${NC} settings.json created with hooks"
          fi
      fi

      echo ""
      echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo -e "${GREEN}[KUARK]${NC} Setup complete!"
      echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo -e "  ${CYAN}Agents:${NC}   16 specialized AI agents"
      echo -e "  ${CYAN}Skills:${NC}   10 skill modules"
      echo -e "  ${CYAN}Hooks:${NC}    SessionStart, PreToolUse, PostToolUse, Stop"
      echo ""
      echo -e "  Start Claude Code in any project and say ${YELLOW}'proje baslat'${NC}"
      echo ""
    EOS
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
