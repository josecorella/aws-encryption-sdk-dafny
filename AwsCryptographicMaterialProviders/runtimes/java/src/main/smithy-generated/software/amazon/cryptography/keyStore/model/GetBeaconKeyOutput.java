// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
// Do not modify this file. This file is machine generated, and any changes to it will be overwritten.
package software.amazon.cryptography.keyStore.model;

import java.nio.ByteBuffer;
import java.util.Objects;

public class GetBeaconKeyOutput {
  private final ByteBuffer beaconKey;

  protected GetBeaconKeyOutput(BuilderImpl builder) {
    this.beaconKey = builder.beaconKey();
  }

  public ByteBuffer beaconKey() {
    return this.beaconKey;
  }

  public Builder toBuilder() {
    return new BuilderImpl(this);
  }

  public static Builder builder() {
    return new BuilderImpl();
  }

  public interface Builder {
    Builder beaconKey(ByteBuffer beaconKey);

    ByteBuffer beaconKey();

    GetBeaconKeyOutput build();
  }

  static class BuilderImpl implements Builder {
    protected ByteBuffer beaconKey;

    protected BuilderImpl() {
    }

    protected BuilderImpl(GetBeaconKeyOutput model) {
      this.beaconKey = model.beaconKey();
    }

    public Builder beaconKey(ByteBuffer beaconKey) {
      this.beaconKey = beaconKey;
      return this;
    }

    public ByteBuffer beaconKey() {
      return this.beaconKey;
    }

    public GetBeaconKeyOutput build() {
      if (Objects.isNull(this.beaconKey()))  {
        throw new IllegalArgumentException("Missing value for required field `beaconKey`");
      }
      return new GetBeaconKeyOutput(this);
    }
  }
}
