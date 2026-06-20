import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Table, Button, Modal, Form, Input, message, Space } from 'antd';
import { PlusOutlined, RightOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { fetchApps, createApp } from '../../api/app-center';
import type { App, CreateAppPayload } from '../../types';

export default function AppsPage() {
  const [open, setOpen] = useState(false);
  const [form] = Form.useForm<CreateAppPayload>();
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  const { data: apps = [], isLoading } = useQuery({
    queryKey: ['apps'],
    queryFn: fetchApps,
  });

  const mutation = useMutation({
    mutationFn: createApp,
    onSuccess: () => {
      message.success('应用创建成功');
      setOpen(false);
      form.resetFields();
      queryClient.invalidateQueries({ queryKey: ['apps'] });
    },
    onError: (err: Error) => {
      message.error(err.message);
    },
  });

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id' },
    { title: '名称', dataIndex: 'name', key: 'name' },
    { title: '描述', dataIndex: 'description', key: 'description' },
    {
      title: '创建时间', dataIndex: 'created_at', key: 'created_at',
      render: (v: string) => new Date(v).toLocaleDateString(),
    },
    {
      title: '操作', key: 'action',
      render: (_: unknown, record: App) => (
        <Button type="link" icon={<RightOutlined />} onClick={() => navigate(`/apps/${record.id}/versions`)}>
          版本管理
        </Button>
      ),
    },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <h2 style={{ margin: 0 }}>应用管理</h2>
        <Button type="primary" icon={<PlusOutlined />} onClick={() => setOpen(true)}>
          新增应用
        </Button>
      </div>

      <Table columns={columns} dataSource={apps} rowKey="id" loading={isLoading} pagination={false} />

      <Modal
        title="新增应用"
        open={open}
        onCancel={() => setOpen(false)}
        onOk={() => form.submit()}
        confirmLoading={mutation.isPending}
      >
        <Form form={form} layout="vertical" onFinish={(values) => mutation.mutate(values)}>
          <Form.Item name="id" label="应用 ID" rules={[{ required: true, message: '请输入应用 ID' }]}>
            <Input placeholder="如：flash_im" />
          </Form.Item>
          <Form.Item name="name" label="应用名称" rules={[{ required: true, message: '请输入名称' }]}>
            <Input placeholder="如：闪讯" />
          </Form.Item>
          <Form.Item name="description" label="描述">
            <Input.TextArea placeholder="应用简介" rows={3} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
