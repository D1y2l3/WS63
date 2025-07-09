import { relationalStore } from '@kit.ArkData';

/**
 * 数据库配置类
 * 定义数据库的基本属性，如名称、安全级别等
 */
export class DBConfig {
  /**
   * 数据库存储配置
   * - name: 数据库文件名
   * - securityLevel: 安全级别
   * - encrypt: 是否加密3
   * - isReadOnly: 是否只读
   */
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'user_registration.db', // 数据库文件名为用户注册
    securityLevel: relationalStore.SecurityLevel.S1, // 安全级别S1
    encrypt: false, // 不加密数据库
    isReadOnly: false // 非只读模式
  };
}

/**
 * 数据库表定义类
 * 用于定义和管理数据库中的表结构
 */
export class DBTable {
  public static Instance: DBTable; // 单例实例
  public TableName: string; // 表名称
  public SQLCreateTable: string | null = null; // 创建表的SQL语句
  public Columns: Array<string>; // 表的列名数组

  /**
   * 构造函数
   * @param tableName 表名称
   * @param sqlCreateTable 创建表的SQL语句
   * @param columns 表的列名数组
   */
  constructor(tableName: string, sqlCreateTable: string | null, columns: Array<string>) {
    this.TableName = tableName;
    this.SQLCreateTable = sqlCreateTable;
    this.Columns = columns;
  }

  /**
   * 获取用户注册信息表的实例
   * 使用单例模式确保表定义的唯一性
   * @returns 用户注册表的实例
   */
  public static GetUSERREGISTERDBTableInstance() {
    DBTable.Instance = new DBTable('UserRegistrationTable',
      // 创建用户注册表的SQL语句，包含ID、手机号、密码和邮箱字段
      'CREATE TABLE IF NOT EXISTS UserRegistrationTable(' +
        'ID TEXT PRIMARY KEY,' + // 主键ID，文本类型
        'PhoneNumber TEXT, ' + // 手机号码，文本类型
        'Password TEXT, ' + // 密码，文本类型
        'Email TEXT ' + // 邮箱，文本类型
        ')',
      // 表的列名数组
      ['ID', 'PhoneNumber', 'Password', 'Email']);
    return DBTable.Instance;
  }
}

/**
 * 用户注册信息接口
 * 定义用户注册数据的结构
 */
export interface IUserRegistration {
  id: string; // 用户唯一标识ID
  phoneNumber: string; // 手机号码
  password: string; // 登录密码
  email: string; // 电子邮箱
}

/**
 * 用户注册实体类
 * 实现用户注册信息接口，用于创建和操作用户注册数据对象
 */
export class UserRegistrationEntity implements IUserRegistration {
  id: string; // 用户ID
  phoneNumber: string; // 手机号码
  password: string; // 密码
  email: string; // 邮箱

  /**
   * 构造函数
   * @param options 用户注册信息对象
   */
  constructor(options: IUserRegistration) {
    this.id = options.id; // 初始化用户ID
    this.phoneNumber = options.phoneNumber; // 初始化手机号码
    this.password = options.password; // 初始化密码
    this.email = options.email; // 初始化邮箱
  }
}
