# Equivalence-based Mutation of CPS models

## Mutation Strategies

### Delete dead block and directly connect predecessors and successors

Issue: May change semantics in live path

Code:

    MUTATOR_DECORATORS = {
        @emi.decs.TypeAnnotateEveryBlock
        @emi.decs.DeleteDeadDirectReconnect
        };

