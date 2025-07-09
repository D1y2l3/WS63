// // src/model/GlobalUserState.ts
// import {
//   openLocalStorage,
//   LocalStorage,
//   LocalStorageAccessMode,
//   LocalStorageData
// } from '@ohos.data.storage.localStorage';
//
// export class GlobalUserState {
//   private static instance: GlobalUserState;
//   private _isLoggedIn: boolean = false;
//   private _phoneNumber: string = '';
//   private storage: LocalStorage | null = null;
//
//   // 单例模式
//   public static getInstance(): GlobalUserState {
//     if (!GlobalUserState.instance) {
//       GlobalUserState.instance = new GlobalUserState();
//       GlobalUserState.instance.initStorage();
//     }
//     return GlobalUserState.instance;
//   }
//
//   // 初始化存储（使用 async/await）
//   private async initStorage(): Promise<void> {
//     try {
//       const storage = await openLocalStorage({
//         name: 'user_state',
//         accessMode: LocalStorageAccessMode.PRIVATE
//       });
//       this.storage = storage;
//       await this.restoreState(); // 等待状态恢复
//     } catch (err) {
//       console.error('初始化存储失败:', err);
//     }
//   }
//
//   // 登录方法
//   public login(phoneNumber: string): void {
//     this._isLoggedIn = true;
//     this._phoneNumber = phoneNumber;
//     this.saveToStorage();
//   }
//
//   // 登出方法
//   public logout(): void {
//     this._isLoggedIn = false;
//     this._phoneNumber = '';
//     this.clearStorage();
//   }
//
//   // 保存到本地存储
//   private async saveToStorage(): Promise<void> {
//     if (!this.storage) return;
//     try {
//       await this.storage.set('isLoggedIn', this._isLoggedIn);
//       await this.storage.set('phoneNumber', this._phoneNumber);
//     } catch (err) {
//       console.error('保存用户状态失败:', err);
//     }
//   }
//
//   // 清除存储
//   private async clearStorage(): Promise<void> {
//     if (!this.storage) return;
//     try {
//       await this.storage.clear();
//     } catch (err) {
//       console.error('清除用户状态失败:', err);
//     }
//   }
//
//   // 恢复状态
//   public async restoreState(): Promise<void> {
//     if (!this.storage) return;
//     try {
//       const result: LocalStorageData = await this.storage.getAll();
//       this._isLoggedIn = result.has('isLoggedIn') ? result.get('isLoggedIn') : false;
//       this._phoneNumber = result.has('phoneNumber') ? result.get('phoneNumber') || '' : '';
//     } catch (err) {
//       console.error('恢复用户状态失败:', err);
//       this._isLoggedIn = false;
//       this._phoneNumber = '';
//     }
//   }
//
//   // 只读属性
//   public get isLoggedIn(): boolean {
//     return this._isLoggedIn;
//   }
//
//   public get phoneNumber(): string {
//     return this._phoneNumber;
//   }
// }
//
//
//
// baocun.ts
export class GlobalUserState {
  private static instance: GlobalUserState | null = null;
  isLoggedIn: boolean = false;
  phoneNumber: string = '';

  // 单例模式
  static getInstance() {
    if (!GlobalUserState.instance) {
      GlobalUserState.instance = new GlobalUserState();
    }
    return GlobalUserState.instance;
  }

  // 登录方法
  login(phoneNumber: string) {
    this.isLoggedIn = true;
    this.phoneNumber = phoneNumber;
    // 这里可以添加本地存储逻辑（如secureStorage）
  }

  // 登出方法
  logout() {
    this.isLoggedIn = false;
    this.phoneNumber = '';
    // 清空本地存储
  }
}