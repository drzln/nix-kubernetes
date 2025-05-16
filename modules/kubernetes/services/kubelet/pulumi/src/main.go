package main

import (
// corev1 "github.com/pulumi/pulumi-kubernetes/sdk/v4/go/kubernetes/core/v1"
// "github.com/pulumi/pulumi-kubernetes/sdk/v4/go/kubernetes/meta/v1"
// "github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	// pulumi.Run(func(ctx *pulumi.Context) error {
	// 	// Create a namespace
	// 	ns, err := v1.NewNamespace(ctx, "blackmatter", &v1.NamespaceArgs{
	// 		Metadata: &metav1.ObjectMetaArgs{
	// 			Name: pulumi.String("blackmatter"),
	// 		},
	// 	})
	// 	if err != nil {
	// 		return err
	// 	}
	//
	// 	// Create an example ConfigMap in the namespace
	// 	_, err = v1.NewConfigMap(ctx, "example-config", &v1.ConfigMapArgs{
	// 		Metadata: &metav1.ObjectMetaArgs{
	// 			Name:      pulumi.String("example-config"),
	// 			Namespace: ns.Metadata.Name(),
	// 		},
	// 		Data: pulumi.StringMap{
	// 			"config.yaml": pulumi.String("example_key: example_value"),
	// 		},
	// 	})
	// 	if err != nil {
	// 		return err
	// 	}
	//
	// 	ctx.Export("namespace", ns.Metadata.Name())
	//
	// 	return nil
	// })
}
