# xiaou0 dotfiles

这是当前桌面灰—红—白 TUI 风格配置的快照。

## 包含内容

- Hyprland（脚本、音效与窗口规则）
- Waybar、Wofi、Dunst、Quickshell
- Kitty、Alacritty、Fish、Starship、Cava
- Neovim、Yazi、Silicon 主题
- Fcitx5 的横向候选配置与 `obsidian-ember-tui` 主题
- Qutebrowser 的极简界面配置与深色预览样式
- Neovim Typst Preview 的 Chromium 启动配置
- 全局主题源与生成脚本：`.config/theme/`
- Firefox 的 `chrome/` 样式和启用样式所需的 `user.js`
- QQNT 的 LiteLoader 主题插件与用户级桌面入口

## 未包含内容

- Firefox 登录态、Cookie、历史记录和缓存
- QQ 聊天数据与账号数据
- Clash Verge 的代理订阅、节点与运行数据
- Neovim 插件缓存和嵌套 Git 元数据
- Chromium、Qutebrowser 的登录态、缓存、历史记录与书签
- Fcitx5 用户词库、输入历史和缓存布局

## 恢复

先预览：

```bash
./restore.sh
```

确认后应用：

```bash
./restore.sh --apply
```

恢复脚本会先把目标位置的同名配置备份到
`~/.xiaou0_dotfiles_backup_时间戳/`，再合并复制本快照。

Firefox 的 profile 目录名是当前机器生成的
`tygqmu3q.default-release`。换机器后若 profile 名不同，需要把其中的
`chrome/` 和 `user.js` 手动放入新 profile。
