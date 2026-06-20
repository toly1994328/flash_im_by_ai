# fx_admin — 前端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
技术栈：Vite + React 19 + TypeScript + shadcn/ui + TanStack Query + React Router 7

---

## 执行顺序

1. ⬜ 任务 1 — 初始化 Vite 项目 + 安装依赖
2. ⬜ 任务 2 — 配置 Tailwind + shadcn/ui
3. ⬜ 任务 3 — Vite 代理配置
4. ⬜ 任务 4 — TypeScript 类型定义
5. ⬜ 任务 5 — API 请求封装
6. ⬜ 任务 6 — 布局组件（侧栏 + 内容区）
7. ⬜ 任务 7 — 路由配置
8. ⬜ 任务 8 — 应用列表页
9. ⬜ 任务 9 — 版本管理页
10. ⬜ 任务 10 — 验证

---

## 任务 1：初始化 Vite 项目 `⬜ 待处理`

```bash
cd web
npm create vite@latest fx_admin -- --template react-ts
cd fx_admin
npm install
```

安装额外依赖：
```bash
npm install @tanstack/react-query react-router-dom react-hook-form @hookform/resolvers zod
npm install -D tailwindcss @tailwindcss/vite
```

---

## 任务 2：配置 Tailwind + shadcn/ui `⬜ 待处理`

### 2.1 Tailwind 配置 `⬜`

`vite.config.ts` 添加 Tailwind 插件：
```ts
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
})
```

`src/index.css` 顶部：
```css
@import "tailwindcss";
```

### 2.2 初始化 shadcn/ui `⬜`

```bash
npx shadcn@latest init
```

按需安装组件：
```bash
npx shadcn@latest add button table dialog input select form label textarea
```

---

## 任务 3：Vite 代理配置 `⬜ 待处理`

文件：`web/fx_admin/vite.config.ts`

```ts
export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:9600',
        changeOrigin: true,
      }
    }
  }
})
```

---

## 任务 4：TypeScript 类型定义 `⬜ 待处理`

文件：`src/types/index.ts`（新建）

```ts
export interface App {
  id: string;
  name: string;
  description: string | null;
  created_at: string;
}

export interface AppVersion {
  id: number;
  platform: string;
  version: string;
  download_url: string;
  file_size: number;
  sha256: string | null;
  release_notes: string | null;
  force_update: boolean;
  created_at: string;
}

export interface CreateAppPayload {
  id: string;
  name: string;
  description?: string;
}

export interface CreateVersionPayload {
  app_id: string;
  platform: string;
  version: string;
  download_url: string;
  file_size?: number;
  sha256?: string;
  release_notes?: string;
  force_update?: boolean;
}

export interface UpdateVersionPayload {
  download_url?: string;
  file_size?: number;
  sha256?: string;
  release_notes?: string;
  force_update?: boolean;
}
```

---

## 任务 5：API 请求封装 `⬜ 待处理`

文件：`src/api/app-center.ts`（新建）

```ts
import type { App, AppVersion, CreateAppPayload, CreateVersionPayload, UpdateVersionPayload } from '../types';

const BASE = '/api';

// GET /api/app/list
export async function fetchApps(): Promise<App[]>

// POST /api/app
export async function createApp(payload: CreateAppPayload): Promise<void>

// GET /api/app/versions?app_id=xxx
export async function fetchVersions(appId: string): Promise<AppVersion[]>

// POST /api/app/version
export async function createVersion(payload: CreateVersionPayload): Promise<void>

// PUT /api/app/version?app_id=xxx&platform=xxx&version=xxx
export async function updateVersion(
  appId: string, platform: string, version: string,
  payload: UpdateVersionPayload
): Promise<void>
```

每个函数用 `fetch()` 实现，错误时 throw。

---

## 任务 6：布局组件 `⬜ 待处理`

### 6.1 Sidebar `⬜`

文件：`src/components/layout/Sidebar.tsx`（新建）

- 固定宽度 220px，深色背景
- 顶部 logo/标题："fx_admin"
- 菜单项：应用管理（/apps）
- 使用 React Router 的 NavLink 高亮当前路由

### 6.2 AppLayout `⬜`

文件：`src/components/layout/AppLayout.tsx`（新建）

- flex 布局：左侧 Sidebar + 右侧 `<Outlet />`
- 右侧内容区带 padding

---

## 任务 7：路由配置 `⬜ 待处理`

文件：`src/App.tsx`

```tsx
<QueryClientProvider client={queryClient}>
  <BrowserRouter>
    <Routes>
      <Route element={<AppLayout />}>
        <Route path="/" element={<Navigate to="/apps" />} />
        <Route path="/apps" element={<AppsPage />} />
        <Route path="/apps/:appId/versions" element={<VersionsPage />} />
      </Route>
    </Routes>
  </BrowserRouter>
</QueryClientProvider>
```

---

## 任务 8：应用列表页 `⬜ 待处理`

文件：`src/pages/apps/AppsPage.tsx`（新建）

### 8.1 列表展示 `⬜`

- 使用 `useQuery('apps', fetchApps)` 获取数据
- shadcn Table 展示：ID | 名称 | 描述 | 创建时间 | 操作
- 操作列：Link 到 `/apps/:id/versions`

### 8.2 新增应用弹窗 `⬜`

- 页面顶部 "新增应用" Button
- 点击弹出 Dialog，包含表单（id + name + description）
- 使用 React Hook Form + Zod 验证
- 提交调 `createApp()`，成功后 invalidate query 刷新列表

---

## 任务 9：版本管理页 `⬜ 待处理`

文件：`src/pages/versions/VersionsPage.tsx`（新建）

### 9.1 版本列表 `⬜`

- 从 URL 获取 `appId` 参数
- 使用 `useQuery(['versions', appId], () => fetchVersions(appId))` 获取数据
- shadcn Table 展示：平台 | 版本号 | 下载地址 | 大小 | SHA256 | 强制更新 | 发布时间 | 操作
- 顶部 Select 按平台筛选（客户端过滤即可）

### 9.2 新增版本弹窗 `⬜`

- "新增版本" Button
- Dialog 表单：platform（Select）、version、download_url、file_size、sha256、release_notes、force_update（Switch）
- 提交调 `createVersion()`

### 9.3 编辑版本弹窗 `⬜`

- 操作列 "编辑" Button
- Dialog 表单，预填当前值
- 提交调 `updateVersion()`

---

## 任务 10：验证 `⬜ 待处理`

### 10.1 开发服务器运行 `⬜`

```bash
cd web/fx_admin
npm run dev
```

打开 http://localhost:3000

### 10.2 功能验证 `⬜`

- 应用列表正常显示（能看到 id=1 的闪讯）
- 新增应用成功，列表刷新
- 点击应用进入版本管理页
- 新增版本成功
- 编辑版本成功（修改 force_update）
- 平台筛选正常
