/**
 * Environment Configuration
 *
 * All configuration is read from environment variables
 * Never commit sensitive information to version control
 */
export declare const config: {
    readonly app: {
        readonly name: "Alif Online Moral School API";
        readonly version: "1.0.0";
        readonly port: number;
        readonly env: string;
    };
    readonly supabase: {
        readonly url: string;
        readonly anonKey: string;
        readonly serviceKey: string;
    };
    readonly jwt: {
        readonly secret: string;
        readonly expiresIn: string;
    };
    readonly otp: {
        readonly provider: "supabase";
        readonly expirationTime: number;
    };
    readonly email: {
        readonly fromEmail: string;
        readonly fromName: string;
    };
    readonly storage: {
        readonly provider: "supabase";
        readonly bucket: string;
    };
    readonly logging: {
        readonly level: string;
        readonly format: string;
    };
    readonly cors: {
        readonly origins: string[];
        readonly credentials: boolean;
    };
    readonly rateLimit: {
        readonly windowMs: number;
        readonly maxRequests: number;
    };
    readonly database: {
        readonly pool: {
            readonly min: number;
            readonly max: number;
        };
    };
};
/**
 * Validate that all required environment variables are set
 */
export declare function validateConfig(): void;
export default config;
//# sourceMappingURL=config.d.ts.map