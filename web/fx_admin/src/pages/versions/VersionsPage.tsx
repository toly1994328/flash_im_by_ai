import { useState } from 'react';
import { useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Button, Modal, Form, Input, Select, Switch, message, Tag, Space } from 'antd';
import { PlusOutlined, EditOutlined, CheckCircleOutlined, StopOutlined, DeleteOutlined } from '@ant-design/icons';
import { fetchVersions, createVersion, updateVersion, publishVersion, unpublishVersion, deleteVersion } from '../../api/app-center';
import type { AppVersion, CreateVersionPayload, UpdateVersionPayload } from '../../types';

const PLATFORMS = ['android', 'ios', 'windows', 'macos', 'linux', 'ohos'];

export default function VersionsPage() {
  const { appId } = useParams<{ appId: string }>();
  const [createOpen, setCreateOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [editRecord, setEditRecord] = useState<AppVersion | null>(null);
  const [platformFilter, setPlatformFilter] = useState<string>('all');
  const [createForm] = Form.useForm();
  const [editForm] = Form.useForm();
  const queryClient = useQueryClient();

  const { data: versions = [], isLoading } = useQuery({
    queryKey: ['versions', appId],
    queryFn: () => fetchVersions(appId!),
    enabled: !!appId,
  });

  const filteredVersions = platformFilter === 'all'
    ? versions
    : versions.filter(v => v.platform === platformFilter);

  const createMutation = useMutation({
    mutationFn: createVersion,
    onSuccess: () => {
      message.success('版本创建成功');
      setCreateOpen(false);
      createForm.resetFields();
      queryClient.invalidateQueries({ queryKey: ['versions', appId] });
    },
    onError: (err: Error) => message.error(err.message),
  });

  const updateMutation = useMutation({
    mutationFn: (payload: UpdateVersionPayload) =>
      updateVersion(appId!, editRecord!.platform, editRecord!.version, payload),
    onSuccess: () => {
      message.success('版本更新成功');
      setEditOpen(false);
      queryClient.invalidateQueries({ queryKey: ['versions', appId] });
    },
    onError: (err: Error) => message.error(err.message),
  });

  const handleEdit = (record: AppVersion) => {
    setEditRecord(record);
    editForm.setFieldsValue({
      download_url: record.download_url,
      file_size: record.file_size,
      sha256: record.sha256,
      release_notes: record.release_notes,
      force_update: record.force_update,
    });
    setEditOpen(true);
  };

  const publishMutation = useMutation({
    mutationFn: (record: AppVersion) => publishVersion(appId!, record.platform, record.version),
    onSuccess: () => {
      message.success('版本已发布');
      queryClient.invalidateQueries({ queryKey: ['versions', appId] });
    },
    onError: (err: Error) => message.error(err.message),
  });

  const unpublishMutation = useMutation({
    mutationFn: (record: AppVersion) => unpublishVersion(appId!, record.platform, record.version),
    onSuccess: () => {
      message.success('版本已撤回');
      queryClient.invalidateQueries({ queryKey: ['versions', appId] });
    },
    onError: (err: Error) => message.error(err.message),
  });

  const deleteMutation = useMutation({
    mutationFn: (record: AppVersion) => deleteVersion(appId!, record.platform, record.version),
    onSuccess: () => {
      message.success('版本已删除');
      queryClient.invalidateQueries({ queryKey: ['versions', appId] });
    },
    onError: (err: Error) => message.error(err.message),
  });

  const columns = [
    {
      title: '平台', dataIndex: 'platform', key: 'platform',
      render: (v: string) => <Tag color="blue">{v}</Tag>,
    },
    { title: '版本号', dataIndex: 'version', key: 'version' },
    {
      title: '状态', dataIndex: 'published', key: 'published',
      render: (v: boolean) => v
        ? <Tag color="green">已发布</Tag>
        : <Tag color="default">待发布</Tag>,
    },
    {
      title: '下载地址', dataIndex: 'download_url', key: 'download_url',
      ellipsis: true, width: 200,
    },
    {
      title: '大小', dataIndex: 'file_size', key: 'file_size',
      render: (v: number) => v > 0 ? `${(v / 1024 / 1024).toFixed(1)} MB` : '-',
    },
    {
      title: '强制更新', dataIndex: 'force_update', key: 'force_update',
      render: (v: boolean) => v ? <Tag color="red">是</Tag> : <Tag>否</Tag>,
    },
    {
      title: '发布时间', dataIndex: 'created_at', key: 'created_at',
      render: (v: string) => new Date(v).toLocaleString(),
    },
    {
      title: '操作', key: 'action', width: 260,
      render: (_: unknown, record: AppVersion) => (
        <Space>
          {record.published ? (
            <Button type="link" danger icon={<StopOutlined />} onClick={() => {
              Modal.confirm({
                title: '确认撤回',
                content: `撤回 ${record.platform} v${record.version} 后，客户端将无法检测到此版本更新。`,
                okText: '确认撤回',
                okType: 'danger',
                cancelText: '取消',
                onOk: () => unpublishMutation.mutate(record),
              });
            }}>
              撤回
            </Button>
          ) : (
            <Button type="link" icon={<CheckCircleOutlined />} onClick={() => {
              Modal.confirm({
                title: '确认发布',
                content: `发布 ${record.platform} v${record.version} 后，客户端将立即检测到此版本更新。确认商店审核已通过？`,
                okText: '确认发布',
                cancelText: '取消',
                onOk: () => publishMutation.mutate(record),
              });
            }}>
              发布
            </Button>
          )}
          <Button type="link" icon={<EditOutlined />} onClick={() => handleEdit(record)}>
            编辑
          </Button>
          <Button type="link" danger icon={<DeleteOutlined />} onClick={() => {
            Modal.confirm({
              title: '确认删除',
              content: `确定删除 ${record.platform} v${record.version}？此操作不可恢复。`,
              okText: '删除',
              okType: 'danger',
              cancelText: '取消',
              onOk: () => deleteMutation.mutate(record),
            });
          }} />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <Space>
          <h2 style={{ margin: 0 }}>版本管理 - {appId}</h2>
          <Select
            value={platformFilter}
            onChange={setPlatformFilter}
            style={{ width: 120 }}
            options={[
              { label: '全部平台', value: 'all' },
              ...PLATFORMS.map(p => ({ label: p, value: p })),
            ]}
          />
        </Space>
        <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateOpen(true)}>
          新增版本
        </Button>
      </div>

      <Table columns={columns} dataSource={filteredVersions} rowKey="id" loading={isLoading} pagination={false} scroll={{ x: 1200 }} />

      {/* 新增版本弹窗 */}
      <Modal
        title="新增版本"
        open={createOpen}
        onCancel={() => setCreateOpen(false)}
        onOk={() => createForm.submit()}
        confirmLoading={createMutation.isPending}
        width={600}
      >
        <Form
          form={createForm}
          layout="vertical"
          onFinish={(values) => createMutation.mutate({ ...values, app_id: appId })}
          initialValues={{ force_update: false }}
        >
          <Form.Item name="platform" label="平台" rules={[{ required: true }]}>
            <Select options={PLATFORMS.map(p => ({ label: p, value: p }))} />
          </Form.Item>
          <Form.Item name="version" label="版本号" rules={[{ required: true }]}>
            <Input placeholder="1.0.0" />
          </Form.Item>
          <Form.Item name="download_url" label="下载地址" rules={[{ required: true }]}>
            <Input placeholder="https://..." />
          </Form.Item>
          <Form.Item name="file_size" label="文件大小（字节）">
            <Input type="number" placeholder="0" />
          </Form.Item>
          <Form.Item name="sha256" label="SHA256">
            <Input placeholder="文件哈希" />
          </Form.Item>
          <Form.Item name="release_notes" label="更新日志">
            <Input.TextArea rows={3} placeholder="更新内容..." />
          </Form.Item>
          <Form.Item name="force_update" label="强制更新" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>

      {/* 编辑版本弹窗 */}
      <Modal
        title={`编辑版本 - ${editRecord?.platform} ${editRecord?.version}`}
        open={editOpen}
        onCancel={() => setEditOpen(false)}
        onOk={() => editForm.submit()}
        confirmLoading={updateMutation.isPending}
        width={600}
      >
        <Form form={editForm} layout="vertical" onFinish={(values) => updateMutation.mutate(values)}>
          <Form.Item name="download_url" label="下载地址">
            <Input />
          </Form.Item>
          <Form.Item name="file_size" label="文件大小（字节）">
            <Input type="number" />
          </Form.Item>
          <Form.Item name="sha256" label="SHA256">
            <Input />
          </Form.Item>
          <Form.Item name="release_notes" label="更新日志">
            <Input.TextArea rows={3} />
          </Form.Item>
          <Form.Item name="force_update" label="强制更新" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
