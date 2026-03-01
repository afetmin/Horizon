---
layout: default
title: 首页
---

# Horizon

欢迎使用 [Horizon](https://github.com/afetmin/Horizon)，这是一个由 AI 驱动的信息聚合与筛选系统。

## 文档导航

- [配置指南](configuration) — 配置 AI 服务商、信息源、过滤规则与环境变量替换
- [抓取器说明](scrapers) — 了解 Horizon 如何从 GitHub、Hacker News、RSS 与 Reddit 抓取内容
- [评分机制](scoring) — 查看 AI 内容分析流程与 0-10 分评分标准

## 中文速递

<ul>
  {% assign zh_posts = site.posts | where: "lang", "zh" %}
  {% for post in zh_posts limit:20 %}
    <li>
      <a href="{{ post.url | relative_url }}">{{ post.date | date: "%Y-%m-%d" }}</a>
    </li>
  {% else %}
    <li><em>暂无内容</em></li>
  {% endfor %}
</ul>
