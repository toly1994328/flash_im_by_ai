use std::sync::Arc;
use uuid::Uuid;

use crate::models::*;
use crate::repository::FriendRepository;

pub struct FriendService {
    repo: Arc<FriendRepository>,
}

impl FriendService {
    pub fn new(repo: Arc<FriendRepository>) -> Self {
        Self { repo }
    }

    pub fn repo(&self) -> &FriendRepository {
        &self.repo
    }

    /// 发送好友申请
    pub async fn send_request(
        &self,
        from_user_id: i64,
        to_user_id: i64,
        message: Option<&str>,
    ) -> Result<FriendRequest, FriendError> {
        if from_user_id == to_user_id {
            return Err(FriendError::CannotAddSelf);
        }
        if !self.repo.user_exists(to_user_id).await? {
            return Err(FriendError::UserNotFound);
        }
        if self.repo.is_friend(from_user_id, to_user_id).await? {
            return Err(FriendError::AlreadyFriends);
        }
        // 双向检查待处理申请
        if self.repo.find_pending_request(from_user_id, to_user_id).await?.is_some() {
            return Err(FriendError::AlreadyRequested);
        }
        if self.repo.find_pending_request(to_user_id, from_user_id).await?.is_some() {
            return Err(FriendError::AlreadyRequested);
        }
        let request = self.repo.create_request(from_user_id, to_user_id, message).await?;
        Ok(request)
    }

    /// 接受好友申请
    pub async fn accept_request(
        &self,
        request_id: Uuid,
        user_id: i64,
    ) -> Result<FriendRelation, FriendError> {
        let req = self.repo.find_request_by_id(request_id).await?
            .ok_or(FriendError::RequestNotFound)?;
        if req.to_user_id != user_id {
            return Err(FriendError::Forbidden);
        }
        if req.status != FriendRequestStatus::Pending as i16 {
            return Err(FriendError::Forbidden);
        }
        self.repo.update_request_status(request_id, FriendRequestStatus::Accepted as i16).await?;
        let relation = self.repo.create_relation(req.from_user_id, req.to_user_id).await?;
        Ok(relation)
    }

    /// 拒绝好友申请
    pub async fn reject_request(
        &self,
        request_id: Uuid,
        user_id: i64,
    ) -> Result<(), FriendError> {
        let req = self.repo.find_request_by_id(request_id).await?
            .ok_or(FriendError::RequestNotFound)?;
        if req.to_user_id != user_id {
            return Err(FriendError::Forbidden);
        }
        if req.status != FriendRequestStatus::Pending as i16 {
            return Err(FriendError::Forbidden);
        }
        self.repo.update_request_status(request_id, FriendRequestStatus::Rejected as i16).await?;
        Ok(())
    }

    /// 获取好友列表
    pub async fn get_friends(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<FriendWithProfile>, FriendError> {
        Ok(self.repo.get_friends(user_id, limit, offset).await?)
    }

    /// 删除好友
    pub async fn delete_friend(
        &self,
        user_id: i64,
        friend_id: i64,
    ) -> Result<(), FriendError> {
        if !self.repo.is_friend(user_id, friend_id).await? {
            return Err(FriendError::RelationNotFound);
        }
        self.repo.delete_relation(user_id, friend_id).await?;
        Ok(())
    }

    /// 获取收到的申请
    pub async fn get_received_requests(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<FriendRequestWithProfile>, FriendError> {
        Ok(self.repo.get_received_requests(user_id, limit, offset).await?)
    }

    /// 获取发送的申请
    pub async fn get_sent_requests(
        &self,
        user_id: i64,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<FriendRequestWithProfile>, FriendError> {
        Ok(self.repo.get_sent_requests(user_id, limit, offset).await?)
    }
}
