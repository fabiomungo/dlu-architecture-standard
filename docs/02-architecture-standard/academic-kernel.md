# Academic Kernel

The Academic Kernel is the stable core of the DLU Academic Operating System.

## Engines

- Identity Engine
- Academic Cognitive Engine (ACE)
- Knowledge Engine
- Competency Engine
- Digital Twin Engine
- Learning Engine
- Assessment Engine
- Credential Engine
- Academic GPS Engine
- Workflow Engine
- Event Mesh

```mermaid
flowchart LR
    UI[Experiences] --> API[API & Experience Gateway]
    API --> K[Academic Kernel]
    K --> ACE[ACE]
    K --> DT[Digital Twin Engine]
    K --> KG[Knowledge Engine]
    K --> CG[Competency Engine]
    K --> GPS[Academic GPS]
    K --> EVT[Event Mesh]
```
