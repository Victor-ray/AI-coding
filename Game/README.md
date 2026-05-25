# 狱火爬升

地狱主题的肉鸽卡牌游戏，使用 Godot 4.3 开发。

## 游戏介绍

玩家扮演一个在地狱中突围的冤魂，通过卡牌战斗击败各路鬼神，最终逃出无间地狱。

## 主要特性

- **5大流派**：狱火/白骨/血煞/幽魂/轮回，每种有不同的卡牌和战斗风格
- **卡牌战斗**：手牌拖拽出牌，能量限制，支持攻击/技能/能力三种类型
- **Boss AI**：神经网络驱动的Boss行为决策系统，支持DeepSeek大模型接入
- **剧情场景**：对话立绘焦点系统，实现"谁说话谁亮"的视觉切换
- **商店/休息/奖励**：丰富的地图事件和卡牌获取机制

## 技术栈

- Godot 4.3
- GDScript
- DeepSeek API（可选）
- 神经网络AI

## 运行

需要 Godot 4.3+，打开 `project.godot` 即可运行。

或直接运行编译好的 `狱火爬升.exe`。

## 项目结构

```
Game/
├── Assets/          # 字体等资源
├── Data/            # 卡牌数据结构
├── Scenes/         # 场景文件
├── Scripts/        # 脚本（含BossAI）
├── Tools/           # 训练工具
├── picture/         # 图片资源
├── Global.gd       # 全局数据
└── project.godot   # 项目配置
```
文档链接🔗（含有安装包）：https://my.feishu.cn/wiki/H4IewobHwi7SpikY7WMc3Z4rn6c?from=from_copylink
