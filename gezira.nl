Point :: [x, y : Real]
Bezier :: [A, B, C : Point]
Pixel :: [a, r, g, b : ColorComponent]
Image :: [[Pixel]]
CoverageAlpha :: ColorComponent
PixelComposition :: [A, B : Pixel]
Texturer :: CoverageAlpha >> Pixel
Compositor :: PixelComposition >> Pixel
EdgeContribution :: [at, width, height : Point, Real, Real]
Matrix :: [a, b, c, d, e, f : Real]

(M : Matrix ∙ P : Point) : Point
    [M.a ∙ P.x + M.c ∙ P.y + M.e,
     M.b ∙ P.x + M.d ∙ P.y + M.f]

TransformBezier (M : Matrix) : Bezier >> Bezier
    ∀ [A, B, C]
        [M ∙ A, M ∙ B, M ∙ C]

ClipBezier (min, max : Point) : Bezier >> Bezier
    ∀ [A, B, C]
        bmin <- A <| B <| C
        bmax <- A |> B |> C
        if ∧[min ≤ bmin ∧ bmax ≤ max]
            [A, B, C] >>
        elseif ∨[bmax ≤ min ∨ max ≤ bmin]
            A' <- min |> A <| max
            C' <- min |> C <| max
            [A', A' ~~ C', C'] >>
        else 
            AB      <- A ~~ B
            BC      <- B ~~ C
            ABBC    <- AB ~~ BC
            nearmin <- | ABBC - min | < 0.1
            nearmax <- | ABBC - max | < 0.1
            M       <- nearmin ? min : nearmax ? max : ABBC
            [A, AB, M] >> [M, BC, C] >> self

DecomposeBezier : Bezier >> EdgeContribution
    ∀ [A, B, C]
        if ∧[ ⌊ A ⌋ = ⌊ C ⌋ ∨ ⌈ A ⌉ = ⌈ C ⌉ ]
            at     <- ⌊ A ⌋ <| ⌊ C ⌋
            width  <- at.x + 1 - (C.x ~~ A.x)
            height <- C.y - A.y
            [at, width, height] >>
        else
            AB      <- A ~~ B
            BC      <- B ~~ C
            ABBC    <- AB ~~ BC
            min     <- ⌊ ABBC ⌋
            max     <- ⌈ ABBC ⌉
            nearmin <- | ABBC - min | < 0.1
            nearmax <- | ABBC - max | < 0.1
            M       <- nearmin ? min : nearmax ? max : ABBC
            [A, AB, M] >> [M, BC, C] >> self

FillBetweenEdges (x : Real) : EdgeContribution >> CoverageAlpha
    local <- 0
    run   <- 0
    ∀ [at, width, height]
        n <- at.x - x
        if n = 0
            local <- local + width ∙ height
            run   <- run   + height
        else
            | local | <| 1 >>
            | run   | <| 1 >(n - 1)>
            x     <- at.x
            local <- run + width ∙ height
            run   <- run + height

SolidColor (offset : Point, color : Pixel) : Texturer
    ∀ coverage
        color ∙ coverage >>

CompositeOver : Compositor
    ∀ [A, B]
        A + B ∙ (1 - A.a) >>

PixelPipeline (target     : Image,
               texturer   : Texturer,
               compositor : Compositor) : EdgeContribution >> _
    first [at, _, _]
        self >> FillBetweenEdges (at.x) >>
                Interleave (texturer (at), ReadArray (target[at.y], at.x)) >>
                compositor >> WriteArray (target[at.y], at.x)

Renderer (target     : Image,
          texturer   : Texturer,
          compositor : Compositor) : Bezier >> _
    self >> ClipBezier (0, 0, target[0].size, target.size) >>
            DecomposeBezier >> GroupBy ('at.y) >> SortBy ('at.x) >>
            PixelPipeline (target, texturer, compositor)