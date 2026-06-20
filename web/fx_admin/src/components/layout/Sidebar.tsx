import { Layout, Menu, Select } from 'antd';
import { AppstoreOutlined, TagsOutlined } from '@ant-design/icons';
import { useNavigate, useLocation, useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { fetchApps } from '../../api/app-center';

const { Sider } = Layout;

export default function Sidebar() {
  const navigate = useNavigate();
  const location = useLocation();

  // 从 URL 提取当前 appId
  const match = location.pathname.match(/\/apps\/([^/]+)/);
  const currentAppId = match ? match[1] : undefined;

  const { data: apps = [] } = useQuery({
    queryKey: ['apps'],
    queryFn: fetchApps,
  });

  const handleAppChange = (appId: string) => {
    navigate(`/apps/${appId}/versions`);
  };

  // 选中应用后的子菜单
  const appMenuItems = currentAppId ? [
    {
      key: `/apps/${currentAppId}/versions`,
      icon: <TagsOutlined />,
      label: '版本管理',
    },
  ] : [];

  // 顶级菜单
  const topMenuItems = [
    {
      key: '/apps',
      icon: <AppstoreOutlined />,
      label: '应用列表',
    },
  ];

  return (
    <Sider width={240} theme="dark">
      <div style={{ height: 64, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <span style={{ color: '#fff', fontSize: 18, fontWeight: 600 }}>fx_admin</span>
      </div>

      {/* 应用选择器 */}
      {apps.length > 0 && (
        <div style={{ padding: '0 16px 12px' }}>
          <Select
            value={currentAppId}
            placeholder="选择应用"
            style={{ width: '100%' }}
            onChange={handleAppChange}
            options={apps.map(app => ({ label: app.name, value: app.id }))}
            allowClear
            onClear={() => navigate('/apps')}
          />
        </div>
      )}

      {/* 菜单 */}
      <Menu
        theme="dark"
        mode="inline"
        selectedKeys={[location.pathname]}
        items={[...topMenuItems, ...appMenuItems]}
        onClick={({ key }) => navigate(key)}
      />
    </Sider>
  );
}
