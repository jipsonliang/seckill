DROP PROCEDURE execute_seckill;

DELIMITER $$ -- console ;定义存储过程
-- 定义存储过程
CREATE PROCEDURE execute_seckill
  (in v_seckill_id BIGINT,in v_phone BIGINT,in v_kill_time TIMESTAMP,OUT r_result int)
  BEGIN
    DECLARE insert_count INT DEFAULT 0;
    START TRANSACTION;
    INSERT IGNORE INTO success_killed(seckill_id, user_phone,state,create_time)
    VALUES
      (v_seckill_id,v_phone,1,v_kill_time);
    SELECT row_count() INTO insert_count;
    IF (insert_count = 0)THEN -- 重复秒杀
      ROLLBACK ;
      set r_result = -1;
    ELSEIF (insert_count < 0) THEN -- 秒杀出错或者等待行锁超时
      ROLLBACK ;
      SET r_result = -2;
    ELSE
      UPDATE seckill SET number = number-1
      WHERE seckill_id = v_seckill_id
      AND end_time > v_kill_time
      AND start_time < v_kill_time
      AND number > 0;
      SELECT row_count() INTO insert_count;
      IF (insert_count = 0) THEN -- 秒杀结束
        ROLLBACK ;
        SET r_result = 0;
      ELSEIF (insert_count < 0) THEN -- 插入失败，等待锁超时
        ROLLBACK ;
        SET r_result = -2;
      ELSE
        COMMIT ;
        SET r_result = 1;
        END IF ;
    END IF ;

  END;
$$
-- 存储过程定义结束

# DELIMITER ;
# set @r_result = -3;
# call execute_seckill(1003,13878688209,now(),@r_result);
# SELECT @r_result;