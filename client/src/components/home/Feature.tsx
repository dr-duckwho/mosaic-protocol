interface FeatureProps {
  title: string;
  description?: string;
}

export function Feature({ title, description }: FeatureProps) {
  return (
    <div className="px-6">
      <h2 className="text-subtitle font-medium text-3xl text-center mb-3">
        {title}
      </h2>
      {description && (
        <p className="text-paragraph text-center mb-24">{description}</p>
      )}
    </div>
  );
}
