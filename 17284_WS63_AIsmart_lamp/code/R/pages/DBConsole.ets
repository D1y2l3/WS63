import { relationalStore } from '@kit.ArkData';
import { Context } from '@ohos.arkui.UIContext';
import ArrayList from '@ohos.util.ArrayList';
import promptAction from '@ohos.promptAction';
import { DBConfig, DBTable, IUserRegistration, UserRegistrationEntity } from './enrollmentArtDate';

/**
 * 数据库控制台
 * 用于添删改查数据库表
 */
export class DBConsole {
  /** 数据库连接对象 RdbStore */
  public RDBStore: relationalStore.RdbStore | null = null;
  /** 数据库表 DBTables */
  public DBTables: ArrayList<DBTable> | undefined;

  /**
   * 构造函数
   * 参数为数据库表的 ArrayList 集合类型
   */
  constructor(dbTables?: ArrayList<DBTable>) {
    if (!this.DBTables && dbTables) {
      this.DBTables = dbTables;
    } else {
      this.DBTables = new ArrayList<DBTable>();
    }
  }

  /**
   * 获取数据库连接 RdbStore，如果不存在数据库表 StudentInfo，创建它
   * 参数为一个不带参数的回调函数
   */
  public GetDBStore(callback: Function) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      console.info('callback 回调函数不能为空！');
      promptAction.showToast({ message: 'callback 回调函数不能为空！', duration: 3000 });
      return;
    }
    if (this.RDBStore !== null) {
      console.info('数据库连接对象已初始化！');
      // 移除不必要的UI提示
      // promptAction.showToast({ message: '数据库连接对象已初始化！', duration: 3000 });
      callback();
    } else {
      let context: Context = getContext(this) as Context;
      relationalStore.getRdbStore(context, DBConfig.STORE_CONFIG, (err, rdb) => {
        if (err) {
          console.error('错误：' + err);
          promptAction.showToast({ message: '错误：' + err, duration: 3000 });
          return;
        }
        if (rdb !== null) {
          this.RDBStore = rdb;
          if (this.DBTables) {
            for (let i = 0; i < this.DBTables.length; i++) {
              if (this.DBTables[i].SQLCreateTable) {
                this.RDBStore.executeSql(this.DBTables[i].SQLCreateTable);
              }
            }
          }
          console.info('成功创建数据库和数据库表！'); // 保留控制台日志，但移除UI提示
          // 移除不必要的UI提示
          // promptAction.showToast({ message: '成功创建数据库和数据库表！', duration: 3000 });
          callback();
        }
      });
    }
  }
}
