import type { ScoringContext, CalculatedScore } from '../../types/domain';
export declare class ScoringValidationError extends Error {
    constructor(message: string);
}
export declare class ScoringService {
    calculateScore(context: ScoringContext): CalculatedScore;
    private calculateRatingScore;
    private calculateQuantityScore;
}
//# sourceMappingURL=scoring-service.d.ts.map