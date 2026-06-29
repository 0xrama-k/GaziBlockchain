1. Input intake
    
    - paste code
    
    - upload .sol file
    

1. Input validation
    
    - size, extension, Solidity-like content
    

1. Preprocessing
    
    - preserve line numbers
    
    - extract pragma, contracts, functions, imports
    

1. Solidity parsing
    
    - AST parse if possible
    
    - fallback to pattern-based parsing if AST fails
    

1. Rule engine analysis
    
    - deterministic custom checks
    

1. Slither analysis
    
    - run in sandbox
    
    - normalize Slither JSON output
    
    - fail-soft if unavailable
    

1. LLM contract-level review
    
    - summarize contract purpose
    
    - identify main risk areas
    
    - add contextual observations
    

1. Raw finding normalization
    
    - convert all sources to common model
    

1. Deduplication
    
    - merge same issue across sources
    

1. LLM finding-level explanation
    
    - summary
    
    - technical explanation
    
    - exploit scenario
    
    - fix suggestion
    

1. Risk scoring
    
    - base severity
    
    - confidence
    
    - exploitability
    
    - asset impact
    

1. Report generation
    
    - UI
    
    - JSON
    
    - Markdown